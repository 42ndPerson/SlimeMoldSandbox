import MetalKit

public class Project {
    public static var borderColor: SIMD4<Float> = SIMD4<Float>(0.2,0.2,0.3,1.0)
    public static var backgroundColor: SIMD4<Float> = SIMD4<Float>(0.0,0.0,0.0,0.0)
    public static var entityCount: Int = 400000
    public static var entities: Array<entity> = []
    public static var simulationSettings: SimulationSettings = SimulationSettings()
    public static var viewFrame: CGSize = CGSize(width: 2732, height: 1960)//CGRect(x: 0, y: 0, width: 2732, height: 1960)
    
    public struct SimulationSettings {
        public var blurSigma: Float = 0.12
        public var subtractValue: Float = 0.01//2
        public var entitySpeed: Float = 0.3/780
        public var sensorSensitivity: Float = 1
        public var sensorDiameter: UInt32 = 1
        public var sensorAngle: Float = Float.pi/4
        public var sensorDistance: Float = 39
    }
    
    public static var metalCode = """
#include <metal_stdlib>
using namespace metal;

struct Entity {
    float2 pos [[ attribute(0) ]];
    float rot [[ attribute(1) ]];
    float3 color [[ attribute(2) ]];
};

struct Settings {
    float blurSigma [[ attribute(0) ]];
    float subtractValue [[ attribute(1) ]];
    float entitySpeed [[ attribute(2) ]];
    float sensorSensitivity [[ attribute(3) ]];
    uint sensorDiameter [[ attribute(4) ]];
    float sensorAngle [[ attribute(5) ]];
    float sensorDistance [[ attribute(6) ]];
};

uint hash(uint state) { //Modified xorshift
    state ^= (state << 13);
    state ^= (state >> 17);
    state ^= (state << 5);
    state *= 2654435769u;
    return state;
}

float sense(
    texture2d<float,access::read_write> texture, 
    uint diameter,
    float2 pos,
    float3 targetHue) {
    
    float radius = float(diameter)/2;
    float sum = 0;
    
    for (uint x = (pos.x - radius); x < (pos.x + radius); x++) {
        for (uint y = (pos.y - radius); y < (pos.y + radius); y++) {
            float colorMatch = powr(dot(targetHue/sqrt(3.0), texture.read(uint2(x,y)).rgb), 30); //Scaling factor for if the pixel read matches target hue
            sum += length(float2(x,y) - pos) <= radius ? (dot(normalize(targetHue), normalize(texture.read(uint2(x,y)).rgb)) < 0.99 ? -0.1 : colorMatch)*(length(texture.read(uint2(x,y)).rgb)/length(float2(x,y) - pos)) : 0; //Change color to something more general eventually
        }
    }
    
    return sum/(M_PI_F*radius*radius);
}

float getAngle(float x, float y) {
    if(x == 0) return y >= 0 ? M_PI_F/2.0 : 3.0*M_PI_F/2.0; 
    return atan2(abs(y), -x*(2*(y<0)-1)) + (y >= 0.0 ? 0.0 : M_PI_F);
}

float getAngleBetween(float2 a, float2 b) {
    return acos( dot(a,b) / ( length(a) * length(b) ) );
}

float readPos(
    texture2d<float,access::read_write> texture, 
    float2 pos) {

    return texture.read(uint2(pos.x,pos.y)).g;
}

kernel void entityInit(
    device Entity *entity [[ buffer(0) ]],
    uint thread_pos [[ thread_position_in_grid ]]) {
    
    float theta = 2*M_PI_F*(hash(thread_pos)/4294967295.0);
    float r = 0.05*hash(thread_pos+1)/4294967295.0;
    
    float x = -r*0.75*cos(theta) + 0.5;
    float y = r*sin(theta) + 0.5;
    float rot = theta + M_PI_F;

    bool color1 = true;//hash(thread_pos*uint(x*100))/4294967295.0 > 0.5;
    bool color2 = true;//hash(thread_pos*uint(x*100)+1)/4294967295.0 > 0.5;
    bool color3 = true;//hash(thread_pos*uint(x*100)+2)/4294967295.0 > 0.5;
    float3 color = float3(color1 ? 1.0 : 0.0, color2 ? 1.0 : 0.0, color3 ? 1.0 : 0.0);
    
    entity[thread_pos] = {float2(x, y), rot+M_PI_F, color};
}

kernel void drawBorder(
    constant float4 *borderColor [[ buffer(0) ]],
    texture2d<float,access::read_write> texture [[ texture(0) ]],
    uint2 thread_pos [[ thread_position_in_grid ]]) {

    if(thread_pos.x <= 10 || thread_pos.y <= 10 || thread_pos.x >= texture.get_width()-11 || thread_pos.y >= texture.get_height()-11) {
        texture.write(*borderColor, thread_pos);
    }
    else {
        texture.write(float4(0.0,0.0,0.0,0.0), thread_pos);
    }
}

kernel void slimeViewer(
    device Entity *entity [[ buffer(0) ]],
    device Settings *settings [[ buffer(1) ]],
    texture2d<float,access::read_write> texture [[ texture(0) ]],
    texture2d<float,access::read> edges [[ texture(1) ]],
    uint thread_pos [[ thread_position_in_grid ]]) {
    //Pos
    float2 texSize = float2(texture.get_width(),texture.get_height());
    float2 floatPos = entity[thread_pos].pos*texSize;
    
    texture.write(float4(entity[thread_pos].color, 1.0), uint2(floatPos));
    //texture.write(float4(entity[thread_pos].rot, 0, 0, 1.0), uint2(floatPos));
    
    //Rot
    //Trail Following
    float2 relativeLeftObservationPos = float2(cos(entity[thread_pos].rot-settings->sensorAngle), -1*sin(entity[thread_pos].rot-settings->sensorAngle));
    float2 relativeCenterObservationPos = float2(cos(entity[thread_pos].rot), -1*sin(entity[thread_pos].rot));
    float2 relativeRightObservationPos = float2(cos(entity[thread_pos].rot+settings->sensorAngle), -1*sin(entity[thread_pos].rot+settings->sensorAngle));
    
    float leftBias = sense(texture, settings->sensorDiameter, settings->sensorDistance*relativeLeftObservationPos+floatPos, entity[thread_pos].color);
    float rightBias = sense(texture, settings->sensorDiameter, settings->sensorDistance*relativeRightObservationPos+floatPos, entity[thread_pos].color);
    float centerBias = sense(texture, settings->sensorDiameter, settings->sensorDistance*relativeCenterObservationPos+floatPos, entity[thread_pos].color);

    float trailDelta = 0;
    if(centerBias>leftBias && centerBias>rightBias) {}
    else if(centerBias<leftBias && centerBias<rightBias) {
        trailDelta -= (M_PI_F/4)*(2*int(hash(thread_pos+int(entity[thread_pos].pos.x))/4294967295.0)-1);
    }
    else if(leftBias<rightBias) {
        trailDelta += M_PI_F/4;
    }
    else if(rightBias<leftBias) {
        trailDelta -= M_PI_F/4;
    }

    //Coordinate Axis Are Typical Counter-Clockwise from Positive x-Axis in Radians
    float4 edgeVal = edges.read(uint2(floatPos));
    float2 edgeNormal = edgeVal.xz - float2(0.5,0.5); //Convert back to signed units
    float2 currentDir = float2(/*-*/cos(entity[thread_pos].rot), -sin(entity[thread_pos].rot));
    
    //Reflection
    /*float2 reflection = reflect(
        edgeNormal,
        currentDir);
    float rot = (edgeVal.a == 0.0 || dot(edgeNormal, currentDir) > 0.0) ? entity[thread_pos].rot + trailDelta : getAngle(reflection.x, -reflection.y);*/

    //Random bounce
    float newAngle = getAngle(edgeNormal.x, edgeNormal.y) - M_PI_2_F + M_PI_F*(hash(thread_pos*int(floatPos.x)*int(floatPos.y))/4294967295.0);
    //float2 newDir = float2(cos(newAngle), -sin(newAngle));
    float rot = (edgeVal.a == 0.0 || dot(edgeNormal, currentDir) > 0.0) ? entity[thread_pos].rot + trailDelta : -newAngle;
    
    entity[thread_pos].rot = rot;
    entity[thread_pos].pos.x += cos(rot)*settings->entitySpeed;
    entity[thread_pos].pos.y -= sin(rot)*settings->entitySpeed;
}

kernel void subtract(
    constant float *subtractValue [[ buffer(0) ]],
    texture2d<float,access::read_write> texture [[ texture(0) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    texture.write(texture.read(gid)-float4(*subtractValue, *subtractValue, *subtractValue, 0), gid);
}

kernel void copy(
    texture2d<float,access::read> source [[ texture(0) ]],
    texture2d<float,access::write> target [[ texture(1) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    target.write(source.read(gid), gid);
}

kernel void drawCircle(
    device uint2 *pos [[ buffer(0) ]],
    device uint *radius [[ buffer(1) ]],
    device float4 *color [[ buffer(2) ]],
    texture2d<float,access::write> texture [[ texture(0) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    if(distance(half2(gid.x,gid.y), half2((*pos).x,(*pos).y)) < *radius) texture.write(*color, gid);
}

kernel void drawRect(
    device uint2 *end1 [[ buffer(0) ]],
    device uint2 *end2 [[ buffer(1) ]],
    device uint *radius [[ buffer(2) ]],
    device float4 *color [[ buffer(3) ]],
    texture2d<float,access::write> texture [[ texture(0) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    float2 centerLine = float2(*end2) - float2(*end1);
    float2 traceLine = float2(gid) - float2(*end1);
    float transverseDist = length(traceLine) * cos(getAngleBetween(traceLine, centerLine));
    float radialDist = length(traceLine) * sin(getAngleBetween(traceLine, centerLine));
    
    if(transverseDist < length(centerLine) && transverseDist > 0 && radialDist < *radius) texture.write(*color, gid);
}

kernel void overlay(
    texture2d<float,access::read_write> base [[ texture(0) ]],
    texture2d<float,access::read_write> layer [[ texture(1) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    float4 baseVal = base.read(gid);
    float4 layerVal = layer.read(gid);
    
    float3 baseAdjustedColor = (1.0 - layerVal.a)*baseVal.a*baseVal.rgb;
    float3 layerAdjustedColor = layerVal.a*layerVal.rgb;
    float adjustedAlpha = layerVal.a + baseVal.a*(1.0 - layerVal.a);

    base.write(float4(baseAdjustedColor + layerAdjustedColor, adjustedAlpha), gid);
}

float4 safeRead(
    texture2d<float,access::read_write> texture, 
    int2 pos) {

    return texture.read(
        uint2(
            min(max(pos.x,0), 2732),
            min(max(pos.y,0), 1960)
        )
    );
}

kernel void findEdgeDirections(
    texture2d<float,access::read_write> source [[ texture(0) ]],
    texture2d<float,access::write> edges [[ texture(1) ]],
    uint2 gid [[ thread_position_in_grid ]]) {
    
    int2 rawPos = int2(gid.x, gid.y);
    
    int radius = 5;
    
    float xSum = 0;
    float ySum = 0;
    
    for(int i = -radius; i <= radius; i++) {
        for(int j = -radius; j <= radius; j++) {
            xSum -= (i == 0 ? 0 : (i < 0 ? -1 : 1)) * length(safeRead(source, rawPos+int2(i,j)).rgb)/sqrt(3.0);
            ySum -= (j == 0 ? 0 : (j < 0 ? -1 : 1)) * length(safeRead(source, rawPos+int2(i,j)).rgb)/sqrt(3.0);
        }
    }
    
    if(abs(xSum) > 0.01 || abs(ySum) > 0.01) {
        edges.write(
            float4(
                xSum/(2*radius*radius) + 0.5,
                ySum/(2*radius*radius) + 0.5,
                ySum/(2*radius*radius) + 0.5,
                1.0), 
            gid);
    } else {
        edges.write(float4(0.0,0.0,0.0,0.0), gid);
    }
}
"""
}
