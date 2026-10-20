# _2IV60 assignments_ 

_Q1, Academic year 2025-2026_ 

## _1 Introduction_ 

For the practical component of 2IV60, you are going to implement some well-known computer graphic concepts, namely, morphing, shading, environment mapping, splines, and volume rendering. You will realize this through so-called GLSL shader programs that run in a shader development environment, called SHADERed. 

## _2 Prerequisites & prior knowledge_ 

The text of this assignment does not pretend to be complete. If you feel that some of the material is unclear, you need to check out the material that we make available in Canvas. There you will find at least the following items. 

1. SHADERed program and links to online documentation; 

2. Our SHADERed tutorial; 

3. Lecture slides; 

4. Links to online resources regarding GLSL. 

## _3 Modus operandi_ 

- The assignment is done in groups of exactly two students. 

- The assignment is subdivided in exercises. The results of the exercises marked with the canvas logo are to be submitted through Canvas, among others for grading and fraud detection. 

- Each exercise is graded based on the following: 

   - The expected approach as described in this document; 

   - The criteria given in the corresponding Canvas rubric; 

   - Sufficient, clear, and, correct documentation in the shaders; 

   - Correct visual output. 

2iv60 assignments 2 

## _4 Week 2, Exercise 1/2: Morphing_ 

morphing is a technique to change the shape of an object using continuous animation. A morphing effect can be achieved if a vertex shader computes a time-dependent vertex position<sup>1</sup> . 



- Open the project called morph.sprj. Modify the skeleton vertex shader so that the morphing effect works on the given _unit sphere_<sup>2</sup> , as shown in the morphing demo video in Canvas. 

1 Remember that SHADERed has a uniform variable that keeps the time. 

2 Sphere with radius 1, centered around the origin. 

First, make the sphere visible: 

- Compute the Model-View-Projection matrix in function main() using the system variables, representing Geometry/Modeling and View-Projection transformation matrices. 

- Compute gl_Position, using the Model-View-Projection matrix and vector p. The variable gl_Position represents the position of the current vertex in _homogeneous_ coordinates. 

Second, implement the morphing: 

- Do the computations in Model space. 

- Start with computing the intersection<sup>3</sup> of the unit cube<sup>4</sup> with the half-line starting in the origin and incident with the current vertex. 

      - 3 Use preparation exercise in section 9. 

      - 4 A unit cube has dimensions [ _−_ 1, 1] _×_ 

      - [ _−_ 1, 1] _×_ [ _−_ 1, 1]. 

- Convert intersection into an offset of the cube face at hand using some periodic function. 

   - Complete function offset () by assigning to variable limit<sup>5</sup> . And by assigning a suitable value to the variable bias<sup>6</sup> . 

- 5 Think about what variable restriction actually represents. 

- 6 You can leave this step for now, and once the animation is working, you can start experimenting to find a suitable bias. 

2iv60 assignments 3 

## _5 Week 2, Exercise 2/2: Phong Shading_ 

phong shading is a shading technique based on normal vector interpolation resulting in more realistic highlights and reduced Mach banding. 

- I Open the project called phong.sprj and implement Phong shading by adapting both the vertex shader and the fragment shader. 

- Compute in the vertex shader for a given vertex and normal in model space, the vertex position P and normal vector N in eye space, using the camera’s view matrix mat4 matV, and the modelling transformation matrix mat4 matGeo. 

- Use the interpolated input for the fragment shader, P and N, in the shading function to compute the actual Phong shading<sup>7</sup> when given also a light source and a material specification. 

- 7 The details can be found in the shading lecture slides. 

<mark>vec4 shading ( vec3 P , vec3 N, LightSource light , Material m)</mark> 

2iv60 assignments 4 

## _6 Week 3, Exercise 1/1: Environment mapping_ 





environment mapping is a long-standing texture mapping technique used to enhance the realism of a rendered scene by taking into account the reflection of the environment in an object. Here we consider cube mapping<sup>8</sup> where the environment is a unit cube<sup>9</sup> (in Model space) textured with a cube map, a texture in the shape of an unfolded cube; see figures 1 and 2. 



Open the project called environment.sprj. Implement environment mapping using a vertex and a fragment shader. 

Follow the remarks in the given template code for the shaders. Furthermore, in the vertex shader consider the following. 

- Assign to vec3 Q the Cartesian coordinates of the shader’s input vertex vec4 P. 

Figure 1: Test cube map. _left_ : with encoding for the axes: x, y, and z are encoded as red, green, and blue, respectively; triangles and dots denote positive axes, crosses negative axes. _right_ : folded to a cube. 

8 See slides on environment mapping. 9 Again: [ _−_ 1, 1] _×_ [ _−_ 1, 1] _×_ [ _−_ 1, 1]. 



Figure 2: Sample cube map. 

- Compute the eye position vec3 E in Cartesian Model space coordinates<sup>10</sup> . 

10 _Hint:_ The eye position is located in the origin in Eye space. 

- Compute vec3 I, the vector from P towards the camera, in Cartesian Model coordinates. 

- Finally, reflect vector vec3 I in input normal vec3 N and assign the result to vec3 R. 

The vector varying vec3 R is interpolated and passed to the fragment shader to compute a proper texture coordinate in a cube map: 



Figure 3: (left) Unfolded cube map texture showing _x_ , _y_ , _z_ axes orientations on its faces; (right) The corresponding cube and the axes in 3D. 

2iv60 assignments 5 

- First, compute the intersection vec3 h of the reflected vector R with the unit cube<sup>11</sup> . 

- Transform the intersection point to coordinates ( _u_ , _v_ ) _∈_ [ _−_ 1, 1] _×_ [ _−_ 1, 1] on the intersected side of the cube: Avoiding case distinction as much as possible, define a transformation matrix to map ( _u_ , _v_ ) to [1, 0] _×_ [0, 1] coordinates in the cube map. Do so by building matrices for (1) mapping<sup>12,13</sup> ( _u_ , _v_ ) on [0, 8] _×_ [0, 6] using local axes (position and orientation) as shown in Figure 3, and (2) mapping [0, 8] _×_ [0, 6] to [0, 1] _×_ [0, 1]. 

11 Do so in the same manner as in the Morphing assignment. 

12 Follow along the preparation exercise in section 10 to help you setup the appropriate transformations. 

13 Use function mat3 Mat() to construct a 3 _×_ 3 homogeneous matrix from given columns. 

2iv60 assignments 6 

- _7 week 5, Excercise 1/1: Splines in a geometry shader_ 







A _geometry shader_ is an optional shader stage between the vertex and the fragment shader. The geometry shader takes a geometric primitive, consisting of a number of vertices, as input. The shader can then transform the input into a new primitive, consisting of different vertices. A good example for using a geometry shader is the interpolation of curves, like Bézier curves. 



- In this exercise you implement a GLSL effect that constructs a cubic Bézier curve when given four control points – the vertices of a quad. You give the curve a certain width and height to form a track. In a vertex shader you animate a cube that moves along the track. Finally, you change the track into a Möbius band. See video and figure 4. **We** **_require_ you to use matrices in solving sub problems.** 

Figure 4: Eight control points (vertices of two adjacent quads) being transformed into a curve and a surface, using geometry shaders. 



<!-- Start of picture text -->
NC IN<br><!-- End of picture text -->

Figure 5: Construction of a triangle strip. Each generated vertex (blue) forms a triangle with the last two vertices. 

You are given a skeleton project that displays a quad. In the geometry shader, vertices are generated using GLSL function EmitVertex(), see function genVertex(). 

1. Construct a Bézier curve given a quad in _z_ = 0 plane as input in the geometry shader. 

   - First, implement the curve functions evalBezier( float t ,mat4 G) and evalBezierTan(float t , mat4 G) to return a point on the cubic curve<sup>14</sup> at parameter t and its tangent, respectively. _G_ is the so-called geometry vector that contains a column of control points (row vectors). 

   - Next, make the shader emit vertices along the curve. The amount of segments per curve is defined by the variable uNum. The end results should look similar to the curve in the middle image of figure 4<sup>15</sup> . 

> 14 The four control points are available as gl_in[i ]. gl_Position with _i_ = 0, 1, 2, 3. 

15 Note that you need two quads to come to that result. 

2. Replace the curve by a track symmetric in _z_ = 0 with width 2 _D_ and height 2 _H_ by constructing 4 triangle strips. 

   - First generate<sup>16</sup> a triangle strip<sup>17</sup> for the top of the track by computing a local orthonormal axis system mat4 Orient at point _p_ ( _t_ ) of the curve with x-axis perpendicular to the curve, y-axis tangent to the curve, and z-axis equal to (0, 0, 1)<sup>_T_</sup> . Define the points of the triangle strip in these local axis systems. 

16 In the layout of the geometry shader use triangle-strip instead of line-strip. 17 The construction of the triangle strip is as shown in figure 5. 

2iv60 assignments 7 

   - Similarly<sup>18</sup> , generate triangle strips for the two sides and the bottom of the track. Color the sides in a distinguishing color. 

3. Animate a cube along the track. 

   - Implement the vertex shader of shader pass Anim to move the cube along the curve. (1) Activate the Anim shader pass by clicking eye icon next to it. (2) Implement<sup>19</sup> the evalBezier and evalBezierTan functions. (3) Implement the translation and scaling transformation functions, T(vec3 t) and S(vec3 s). (4) Using those matrices and mat4 Orient construct a local orthornormal axis system in which the [ _−_<sup><u>1</u></sup> 2<sup>,</sup><sup><u>1</u></sup> 2<sup>]</sup><sup>_×_[</sup><sup>_−_</sup> 2<sup><u>1</u>,</sup> 2<sup><u>1</u>]</sup><sup>_×_[</sup><sup>_−_</sup><sup><u>1</u></sup> 2<sup>,</sup><sup><u>1</u></sup> 2<sup>]canbedrawnto</sup> result in the animated cube whose positive y-face is in the tangent direction of the curve. 

18 If you did it correctly, you should see that the only difference between the 4 triangle strips are the chosen local coordinates, making this an ideal candidate for implementation with a function with two points given in local coordinates as parameters. 

19 Reuse code from the geometry shader, but modify to use the control points _P_ 0, _P_ 1, _P_ 2, _P_ 3 as parameters. 

4. Replace the track by a Möbius band. 

   - Use a mat4 Twist transformation to change the track generation in the geometry shader and the animation in the vertex shader accordingly. 

   - Add a switch in the GUI to switch the Möbius band on and off. 

2iv60 assignments 8 

- _8 Week 7, Exercise 1/1, Path Tracing_ 



Figure 6: Path tracer with purple sky, white area light and metallic/glossy objects rendered with, sometimes fuzzy, specular reflections. 

ray tracing simulates light by tracing rays from the camera into a scene, accurately modeling reflections and shadows using geometric precision. It typically follows deterministic paths and simplified lighting models. Traditional implementations rely on recursion, which is not available in GLSL. path tracing introduces randomness to ray behavior, allowing rays to bounce and sample light stochastically. This produces noise that must be reduced by averaging many samples. While full path tracing can capture global illumination effects, our implementation focuses on specular reflections with perturbations, omitting diffuse lighting and transparency. 



In this assignment you are going to build a GPU-accelerated path tracing using GLSL; see figure 6 for a possible outcome. You are given a skeleton code in which you have to implement, among others, intersection algorithms and tracing of rays. The intersection computations have to be done in model space. The scenes you are going to render consist of transformed _unit objects_ : unit spheres<sup>20</sup> and unit cubes<sup>21</sup> . These objects are placed into the world by applying a homogeneous transformation matrix _TRS_ , which combines translation ( _T_ ), rotation ( _R_ ), and scaling ( _S_ ). 

The fragment shader of the skeleton code already contains most important functionality for this exercise. In the main function, function computeColor is called. Inside, calculateFinalColor is called a number of times, determined by averageCount. The resulting colors after these calls are averaged and returned by function computeColor. Function calculateFinalColor casts a ray with origin rayOrigin and direction rayDir, which is checked for intersections with objects in the scene by the AllObjectsRayTest function. The function returns a hitData structure containing information about the intersection point on the nearest object hit by the ray; see comments in the skeleton code. Depending on the object that is hit, the loop is executed again with a newly computed ray. This continues until the ray hits a light source<sup>22</sup> or reaches 

20 a sphere centered at the origin with radius 1 

> 21 a cube centered at the origin with side length 2 

> 22 The sky is a light source that is modeled as a big sphere around the whole scene. So, there is always a hit. 

2iv60 assignments 9 

its maximum amount of bounces. Every time a ray bounces off of something, the absorbMul variable is decreased so as to simulate light absorption. The initial scene consists of a ground floor, modeled as a box, and a sphere. For something to appear in the preview window, several things need to be done: 

- First, the functions rayUnitSphereIntersect and rayUnitCubeIntersect should be implemented. Afterwards, it should be possible to see a unit sphere and a unit cube<sup>23</sup> . 

- The objects are not yet transformed. So, next fix the transformation matrices in the makeObject function. 

- Fix the AllObjectsRayTest to find the closest object; follow the steps indicated in the code. You now should have something as in Figure 7. 

- Next, in calculateFinalColor, remove the line that prematurely ends the loop over the bounces and update rayOrigin and rayDir to comply with the ray after bouncing off of the object that has been hit. See Figure 8 for the result. 

- Up to this point, the ray tracing is deterministic. Modify it by introducint a random perturbation to the computed reflection vector. To see the effect play with the averageCount parameter in the pinned properties of shaderEd. Make the effect also scalable by using the roughness parameter of objects. 

- Next, construct a scene to showcase your raytracer (see demo video on canvas): at a minimum include local light source(s)<sup>24</sup> , add animation(s) and make use of uniform variables that can be set in the pinned properties in shaderEd. 

- For the enthusiasts: To further enhance this raytracer, you may, for instance, add diffuse reflections<sup>25</sup> , environment mapping, transparency, and objects defined by implicit functions, or make enhancements to speed up the ray tracer. 



<!-- Start of picture text -->
o—<br><!-- End of picture text -->

Figure 7: Intermediate result: white ball, yellow plane, purple sky. 



<!-- Start of picture text -->
a<br><!-- End of picture text -->

Figure 8: Intermediate result: Fully specular sphere and plane. 



<!-- Start of picture text -->
ie,<br><!-- End of picture text -->

Figure 9: A shiny sphere with a much less shiny plane. 23 Note that the cube might hide the sphere. 

24 refer to the sky object for guidance 

25 This can be achieved by randomly deciding at each bounce whether the next interaction is specular or diffuse. In the specular case, the ray is reflected according to the reflection law (with possible perturbations). In the diffuse case, a new ray direction should be chosen randomly according to an appropriate distribution. 

2iv60 assignments 10 

## _9 Appendix: Morphing shader_ 



We consider the intersection of objects with a half-line. A half-line is often used in computer graphics, for instance to model light rays. Here we consider half-lines and objects in **R**<sup>2</sup> . Let _H_ be a half-line starting in the origin with direction _⃗ v_ : 



Figure 10: Vertical slab _Sv_ in green; half line _H_ in blue with direction vector _⃗ v_ ; intersection of half-line _H_ and slab _Sv_ in red. 

2. Use slabs to construct a (filled) unit-square _S_ = [ _−_ 1, 1] _×_ [ _−_ 1, 1]. 

3. Give the _λ_ -interval on _H_ for the intersection _H ∩ S_ of the half-line and the square 

4. What if _vx_ = 0, _vy_ = 0, or both? 

5. What is the intersection point _⃗ i_ of _H_ and the border of the square _S_ . 

6. What is the outward normal vector _⃗ n_ on the square in intersection point _⃗ i_ . 

2iv60 assignments 11 

_10 Appendix: Environment mapping shader_ 



<!-- Start of picture text -->
T<br>o<br>| |<br><!-- End of picture text -->

Figure 11: _left_ : parameter space with _u_ , _v ∈_ [ _−_ 1, 1]; _right_ : texture map with _s ∈_ [0, _S_ ] and _t ∈_ [0, _T_ ]; Q is a quadrangle with axis _⃗ a_ | = ( _ax_ , _ay_ ) and _⃗ b_ = ( _bx_ , _by_ ). 

Consider the side at _y_ = 1 of a unit cube [ _−_ 1, 1] _×_ [ _−_ 1, 1] _×_ [ _−_ 1, 1]. We like to map each point of this side to a color in a texture map [0, _S_ ] _×_ [0, _T_ ] _→ Color_ . 

1. Give a parametric description _P_ ( _u_ , _v_ ) for this side of the cube with parameters _u_ , _v ∈_ [ _−_ 1, 1] . 

2. Construct a homogeneous matrix _H_ that maps parameter points ( _u_ , _v_ ) to texture coordinates ( _s_ , _t_ ) such that the texture map is scaled to fit exactly, but **possibly** with distortion. 

3. Construct a homogeneous matrix _H_ that maps parameter points ( _u_ , _v_ ) to a quadruple _Q_ in texture coordinate space, given by 



