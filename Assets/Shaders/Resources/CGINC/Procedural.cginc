#ifndef PROCEDURAL
#define PROCEDURAL

#define CLUSTERCLIPCOUNT 64
#define CLUSTERVERTEXCOUNT 96
#define PLANECOUNT 6

#ifndef COMPUTESHADER		//Not for compute shader
struct Point{
    float3 vertex;
    float4 tangent;
    float3 normal;
    float2 texcoord;
};

StructuredBuffer<Point> verticesBuffer;
StructuredBuffer<uint> resultBuffer;
static const uint IndexArray[6] = 
{
	0,	1,	2,
	1,	3,	2
};
inline Point getVertex(uint vertexID, uint instanceID)
{
    instanceID = resultBuffer[instanceID];
	uint vertID = instanceID * CLUSTERCLIPCOUNT;	//TODO
	uint triangleCount = IndexArray[vertexID % 6];
	vertID += vertexID / 6 * 4 + triangleCount;
	return verticesBuffer[vertID];
}
#endif
#endif