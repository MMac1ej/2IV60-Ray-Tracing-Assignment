#version 330

out vec4 outColor;

//texture coordinates: normalized fragment coordinates
varying vec2 texCoord;
			
// uniform variables of this render pass
//time 			
uniform float fTime;
uniform int frame;
//mouse position
uniform vec2 vMouseCoord;
//viewport size
uniform vec2 vResolution;
//camera position
uniform vec4 vViewPosition;

// GUI elements
 uniform int averageCount;
 uniform int maxBounces;
 uniform vec3 skyLight;
 uniform bool skyLightSwitch;
 uniform bool showGround;
 uniform bool showSphere;

 uniform bool colorByNormal;
 uniform bool useGammaCorrection;

 // scene controls (to be added as variables of the Simple pass in SHADERed);
 // unset uniforms are 0/false, which freezes the animation and disables the
 // walls, the local lights and the diffuse reflections
 uniform float animSpeed;        // speed multiplier for all animations (0 = frozen)
 uniform vec3  lightColor;       // color of the ceiling area light
 uniform float lightIntensity;   // brightness multiplier of the local light sources
 uniform bool  lightSwitch;      // turns the local light sources on/off
 uniform float sphereRoughness;  // roughness of the big bouncing sphere
 uniform float wallRoughness;    // roughness of the three walls
 uniform bool  showWalls;
 uniform float diffuseChance;    // probability [0,1] that a bounce is diffuse instead of specular


// some basic transformations, as homogeneous 4x4 matrices.
// Note: GLSL matrix constructors are column-major, so every group of four
// arguments below is a COLUMN of the matrix.

/* translation over v: v is stored in the fourth column */
mat4 Translate(in vec3 v) {
        return mat4(1, 0, 0, 0,
                    0, 1, 0, 0,
                    0, 0, 1, 0,
                    v.x, v.y, v.z, 1);
}

/* rotation around the y-axis over theta DEGREES (counter-clockwise when looking
   from +y down to the origin) */
mat4 RotateY(in float theta) {
        float s = sin(radians(theta));
        float c = cos(radians(theta));
        return mat4(c, 0, -s, 0,
                    0, 1, 0, 0,
                    s, 0, c, 0,
                    0, 0, 0, 1);
}

/* scaling along the axes with factors v.x, v.y, v.z (on the diagonal) */
mat4 Scale(in vec3 v) {
        return mat4(v.x, 0, 0, 0,
                    0, v.y, 0, 0,
                    0, 0, v.z, 0,
                    0, 0, 0, 1);
}


//--scene data---------------------------------------------------------------------

# define object types
const int TYPE_SPHERE=0;
const int TYPE_CUBE=1;

struct Object {
  bool enabled;
  int type;
  vec3 center;
  vec3 size;
  
  vec3 color;
  float roughness;
  bool isTransparent;
  bool isFloor;
  bool isLight;
  
  mat4 m2w;    // model to world matrix
  mat4 w2m;    // world to model matrix
  mat4 nv;     // normal vector transform 
};


#define NO 9         // number of objects created in animateObjects()
Object objects[NO];

Object makeObject(bool enabled, int type, vec3 center, vec3 size, vec3 color, float roughness, mat4 T, mat4 R, mat4 S) {
    Object obj;
    obj.enabled=enabled;
    obj.type = type;
    obj.center = center;
    obj.size = size;
    obj.color = color;
    obj.roughness = roughness;
    obj.isTransparent = false;
    obj.isFloor = false;
    obj.isLight = false;
    // model to world: first scale the unit object, then rotate it, then translate it
    obj.m2w = T * R * S;

    // world to model: (T*R*S)^-1 = S^-1 * R^-1 * T^-1, built from the cheap inverses
    // of the separate matrices instead of a general inverse():
    //   - T^-1 translates by the negated translation (column 3),
    //   - R^-1 = R^T since R is a rotation (orthonormal),
    //   - S^-1 has the reciprocal scale factors on the diagonal.
    mat4 Tinv = T;
    Tinv[3].xyz = -T[3].xyz;
    mat4 Rinv = transpose(R);
    mat4 Sinv = mat4(1.0);
    Sinv[0][0] = 1.0 / S[0][0];
    Sinv[1][1] = 1.0 / S[1][1];
    Sinv[2][2] = 1.0 / S[2][2];
    obj.w2m = Sinv * Rinv * Tinv;

    // normals do not transform with m2w under non-uniform scaling; they transform
    // with the inverse transpose of m2w, i.e. transpose(w2m). Apply it to (n,0),
    // use only the xyz part of the result (w is meaningless) and normalize.
    obj.nv  = transpose(obj.w2m);
    return obj;
}


/* Scene: a room open towards the camera (floor + left, right and back wall) lit by
   the sky, a white area light panel near the ceiling and a small orbiting light orb.
   Animated: a mirror sphere bouncing on an orbit, a rotating cube and the light orb
   circling around the cube. All animations are driven by t (fTime) * animSpeed.
*/
void animateObjects(float t) {
    float pi = 3.1415926535897932;
    float a = animSpeed * t;   // animation phase

    
    {   // Sky
        vec3 center = vec3(0.0, 0.0, 0.0);
        vec3 size = vec3(10000.0); // surrounds whole scene
        vec3 color = skyLightSwitch?skyLight:vec3(0); 
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[0]=makeObject(true, TYPE_SPHERE, center, size, color,1, T, R, S);
        objects[0].isLight=true;
    }
    
    {   // Shiny sphere: orbits around (-2,*,5) and bounces on the floor (floor top is at y=-2)
        vec3 center = vec3(-2.0 - 2.5 * cos(0.5 * a),
                           -0.5 + 2.0 * abs(sin(1.5 * a)),
                            5.0 + 2.5 * sin(0.5 * a));
        vec3 size = vec3(1.5);
        vec3 color = vec3(0.8);
        float roughness = sphereRoughness;
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[1]=makeObject(showSphere, TYPE_SPHERE, center, size, color, roughness, T, R, S);
    }

    {   //  not so shiny Ground plane
        vec3 center = vec3(0.0, -2.4, 0.0);
        vec3 size = vec3(7.0,0.4,18.0);
        vec3 color = vec3(1,1,0);
        float roughness = 1.0;
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[2]=makeObject(showGround, TYPE_CUBE, center, size, color, roughness, T, R, S);
        objects[2].isFloor = true;
    }

    // three walls, flat boxes standing on the floor edges (floor spans x in [-7,7], z in [-18,18])
    {   // left wall (reddish)
        vec3 center = vec3(-7.2, 4.0, 0.0);
        vec3 size = vec3(0.2, 6.0, 18.0);
        vec3 color = vec3(0.85, 0.35, 0.35);
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[3]=makeObject(showWalls, TYPE_CUBE, center, size, color, wallRoughness, T, R, S);
    }

    {   // right wall (greenish)
        vec3 center = vec3(7.2, 4.0, 0.0);
        vec3 size = vec3(0.2, 6.0, 18.0);
        vec3 color = vec3(0.35, 0.85, 0.45);
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[4]=makeObject(showWalls, TYPE_CUBE, center, size, color, wallRoughness, T, R, S);
    }

    {   // back wall (light grey)
        vec3 center = vec3(0.0, 4.0, 18.2);
        vec3 size = vec3(7.4, 6.0, 0.2);
        vec3 color = vec3(0.8);
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[5]=makeObject(showWalls, TYPE_CUBE, center, size, color, wallRoughness, T, R, S);
    }

    {   // rotating cube standing on the floor (unit cube scaled by 1 -> side 2, bottom at y=-2)
        vec3 center = vec3(3.0, -1.0, 3.0);
        vec3 size = vec3(1.0);
        vec3 color = vec3(0.9, 0.55, 0.2);
        float roughness = 0.1;
        mat4 T = Translate(center);
        mat4 R = RotateY(45.0 + 40.0 * a);   // RotateY takes degrees
        mat4 S = Scale(size);
        objects[6]=makeObject(true, TYPE_CUBE, center, size, color, roughness, T, R, S);
    }

    {   // area light: thin bright panel near the ceiling, modeled like the sky (isLight)
        vec3 center = vec3(0.0, 8.0, 4.0);
        vec3 size = vec3(2.5, 0.05, 2.5);
        vec3 color = lightColor * lightIntensity;
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[7]=makeObject(lightSwitch, TYPE_CUBE, center, size, color, 1.0, T, R, S);
        objects[7].isLight = true;
    }

    {   // small warm light orb circling around the cube
        vec3 center = vec3(3.0 + 2.2 * cos(2.0 * a), 1.0 + 0.5 * sin(3.0 * a), 3.0 + 2.2 * sin(2.0 * a));
        vec3 size = vec3(0.3);
        vec3 color = vec3(1.0, 0.6, 0.2) * lightIntensity;
        mat4 T = Translate(center);
        mat4 R = mat4(1.0);
        mat4 S = Scale(size);
        objects[8]=makeObject(lightSwitch, TYPE_SPHERE, center, size, color, 1.0, T, R, S);
        objects[8].isLight = true;
    }
}

/* returns signed distances (t0,t1) to the intersections of line r0 + t*rd and 
   unit sphere centered around origin, t0 <= t1; 
   if there are no intersections (-1,-1) is returned.
*/
/* Substituting p = r0 + t*rd into |p|^2 = 1 gives a*t^2 + 2*b*t + c = 0 with
   a = rd.rd, b = rd.r0, c = r0.r0 - 1, so t = (-b -/+ sqrt(b^2 - a*c)) / a.
   rd is not assumed to be normalized: after the world-to-model transform it is
   scaled, and keeping it unnormalized makes t equal to the world-space t.
*/
vec2 rayUnitSphereIntersect(vec3 r0, vec3 rd) {
    float a = dot(rd, rd);
    float b = dot(rd, r0);
    float c = dot(r0, r0) - 1.0;
    float discriminant = b*b - a*c;
    if (discriminant < 0.0) return vec2(-1.0, -1.0); // line misses the sphere
    float sqrtD = sqrt(discriminant);
    float t0 = (-b - sqrtD) / a;
    float t1 = (-b + sqrtD) / a;
    return vec2(t0, t1);
}

/* returns signed distances (t0,t1) to the intersections of line r0 + t*rd and 
   axes-aligned unit cube centered around origin with side 2, t0 <= t1; 
   if there are no intersections (-1,-1) is returned.
*/
/* Slab method: the cube is the intersection of the three slabs -1 <= p_i <= 1.
   For each axis the line is inside the slab for t between (-1 - r0_i)/rd_i and
   (1 - r0_i)/rd_i; the line is inside the cube on the intersection [tNear,tFar]
   of these three intervals. If rd_i = 0 the line is parallel to the slab: it is
   either inside it for all t (|r0_i| <= 1) or never (|r0_i| > 1).
*/
vec2 rayUnitBoxIntersect(vec3 r0, vec3 rd) {
    float tNear = -1e30;
    float tFar  =  1e30;
    for (int i = 0; i < 3; i++) {
        if (rd[i] == 0.0) {
            if (abs(r0[i]) > 1.0) return vec2(-1.0, -1.0); // parallel and outside slab
            continue;                                      // parallel and inside slab: no restriction
        }
        float tA = (-1.0 - r0[i]) / rd[i];
        float tB = ( 1.0 - r0[i]) / rd[i];
        tNear = max(tNear, min(tA, tB));
        tFar  = min(tFar,  max(tA, tB));
    }
    if (tNear > tFar) return vec2(-1.0, -1.0); // slab intervals do not overlap: miss
    return vec2(tNear, tFar);
}

/* returns normal for unit cube surface point p */
vec4 computeCubeNormal(vec3 p) {
    vec3 absP = abs(p);
    if (absP.x > absP.y && absP.x > absP.z)
        return vec4(sign(p.x), 0.0, 0.0,0.0);
    else if (absP.y > absP.x && absP.y > absP.z)
        return vec4(0.0, sign(p.y), 0.0,0.0);
    else
        return vec4(0.0, 0.0, sign(p.z),0.0);
}

//-----------------------------------------------------------------------
struct HitData
{   
    float closest;     // distance to closest intersection 
    vec4 intersection; // point in model space
    Object obj;        // the object that has been hit
};

/* finds the closest intersection of the ray rayPos + t*rayDir (t > 0) with all
   enabled objects; the objects must have been set up by animateObjects() before.
*/
HitData AllObjectsRayTest(vec3 rayPos, vec3 rayDir)
{
    // initialize hitdata
    HitData hitData;
    hitData.closest = 999999.0; //keeps track of distance to closest intersection
    hitData.obj = objects[0]; // sky object; object is needed here, eventually will be overridden.

    //all objects
    for(int i = 0; i < NO; i++)
    {
        Object obj = objects[i];
        
        if (!obj.enabled) continue;
        
        // transform the ray to model space: origin as a point (w=1), direction as a
        // vector (w=0). mrd is deliberately not normalized, so a ray parameter t in
        // model space denotes the same point as t in world space and the t values
        // of different objects can be compared directly.
        vec4 mr0 = obj.w2m * vec4(rayPos,1);
        vec4 mrd = obj.w2m * vec4(rayDir,0);

        // compute the ray parameters t0t1 for entry and exit in model space
        vec2 t0t1 = obj.type==TYPE_SPHERE
                ? rayUnitSphereIntersect(mr0.xyz,mrd.xyz)
                : rayUnitBoxIntersect(mr0.xyz,mrd.xyz); 
        
        // closest positive ray parameter: the entry point t0 if it lies in front of
        // the ray origin, otherwise the exit point t1 (ray starts inside the object,
        // e.g. the camera inside the sky sphere). On a miss both are -1 and the
        // test below rejects it.
        float t = t0t1.x > 0.001 ? t0t1.x : t0t1.y;

        // if the new intersection is closer, update hit information
        if( t > 0.001 && t < hitData.closest)
        {
            hitData.closest = t;
            hitData.obj = obj;
            hitData.intersection = mr0 + t * mrd; // hit point in model space (w stays 1)
        }
    }    
    
    //all test finished, return shortest(best) hit data
    return hitData;
}

//--random functions: provided here because GLSL does not have one
float rand01(float seed) { return fract(sin(seed)*43758.5453123); }

/* returns a random direction uniformly distributed on the unit sphere:
   z uniform in [-1,1] and azimuth phi uniform in [0,2pi) give a uniform
   distribution over the sphere surface (Archimedes' hat-box theorem).
*/
vec3 randomUnitVector(float seed) {
    float z   = 2.0 * rand01(seed) - 1.0;
    float phi = 2.0 * 3.1415926535897932 * rand01(seed + 1.0);
    float r   = sqrt(max(0.0, 1.0 - z*z));
    return vec3(r * cos(phi), r * sin(phi), z);
}


//---------------------------------------------------------------------
vec3 calculateFinalColor(vec3 cameraPos, vec3 cameraRayDir, float AAIndex)
{
    //init
    vec3 finalColor = vec3(0.0);
    vec3 absorbMul = vec3(1.0);
    vec3 rayOrigin = cameraPos;
    vec3 rayDir = cameraRayDir;

    // per-pixel random offset, so that neighbouring pixels get different perturbations
    float pixelSeed = 1000.0 * rand01(dot(texCoord, vec2(12.9898, 78.233)));

    //recursion not available in GLSL; replace by looping
    //until hitting any light source || ray bounces too many times
    for(int i = 0; i < maxBounces; i++)
    {
        //+0.0001 to prevent ray already hit @ start pos
        HitData h = AllObjectsRayTest(rayOrigin + rayDir * 0.0001, rayDir);
        
       // rays end at light source
       if (h.obj.isLight) { finalColor = h.obj.color * absorbMul; break; }

        // the next ray starts at the hit point, transformed from model to world space
        rayOrigin = (h.obj.m2w * h.intersection).xyz;

        // normal at the hit point in model space: for the unit sphere the point itself
        // is the outward unit normal, for the unit cube it is the normal of the face hit
        vec3 mNormal = h.obj.type==TYPE_SPHERE
                ? h.intersection.xyz
                : computeCubeNormal(h.intersection.xyz).xyz;
        // transform the normal to world space with the inverse transpose (nv); only the
        // xyz part is meaningful, and scaling changes its length, so normalize again
        vec3 normal = normalize((h.obj.nv * vec4(mNormal,0)).xyz);
        // The random seed differs per pixel, per sample (AAIndex) and per bounce (i), so
        // the averaged samples in computeColor are independent and the noise averages out.
        // seed and seed+1 are used by randomUnitVector, seed+2 for the diffuse decision.
        float seed = pixelSeed + 13.37 * AAIndex + 7.31 * float(i);

        if (rand01(seed + 2.0) < diffuseChance) {
            // diffuse bounce: normal + random unit vector gives a cosine-weighted
            // (Lambertian) distribution of directions over the hemisphere around the normal
            rayDir = normalize(normal + randomUnitVector(seed));
        } else {
            // specular bounce: perfect reflection of the incoming direction in the normal
            rayDir = reflect(rayDir, normal);
            // glossy reflection: perturb the reflected direction by a random unit vector
            // scaled by the roughness of the object (0 = perfect mirror, 1 = very fuzzy)
            rayDir = normalize(rayDir + h.obj.roughness * randomUnitVector(seed));
            // a perturbed ray pointing into the surface is mirrored back to the outside
            if (dot(rayDir, normal) < 0.0) rayDir = reflect(rayDir, normal);
        }
      
        // every bounce absorbs some light (more bounces = darker scene)
        //     - contains a hack for the checkerboard pattern of the floor
        float intensityFactor = (!h.obj.isFloor) ? 1.0: mod(int(200+rayOrigin.x) + int(200+rayOrigin.z),2);
        absorbMul *= (intensityFactor * h.obj.color);
           
        if (colorByNormal)  {   // debugging option to see your normals
           finalColor = 0.5 * (normal + vec3(1.0)); // maps [-1,1] to [0,1]
           break;
        }
    }    
    return finalColor;
}



//-----------------------------------------------------------------------
vec4 computeColor( vec2 fragCoord )
{    
    vec2 uv = fragCoord * 2.0 - 1.0;//transform fragment coords from [0,1] to [-1,1]
    uv.x *= vResolution.x / vResolution.y; //aspect fix

    //allow camera movement along z axis
    vec3 cameraPos = vec3(0.0, 2.0, -40.0 * vViewPosition.z);    
    vec3 cameraCenter = vec3(0.0,2,0);
    
    //camera lookat direction
    vec3 cameraDir = normalize(cameraCenter - cameraPos);
    
    //camera-to-fragment ray direction
    vec3 rayDir = normalize(3*cameraDir + vec3(uv, 0));

    // set up the (animated) scene once per fragment; the objects do not change
    // during tracing, so this need not be repeated for every ray test
    animateObjects(fTime);

    vec3 finalColor = vec3(0);
    for(int i = 1; i <= averageCount; i++)
    {
        finalColor += calculateFinalColor(cameraPos, rayDir, float(i));
    }
    finalColor = finalColor/float(averageCount);//brute force AA & denoise
    
    if (useGammaCorrection)
    	finalColor.rgb = pow(finalColor.rgb,vec3(1.0/2.2));//gamma correction
        
    //result
    return vec4(finalColor.rgb, 1.0);
}


void main(void)
{
    gl_FragColor = computeColor(texCoord);
}

