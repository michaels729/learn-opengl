#version 430 core
out vec4 FragColor;

in vec3 ourColor; // the input variable from the vertex shader (same name and same type)  
in vec2 TexCoord;

uniform sampler2D texture1;
uniform sampler2D texture2;
uniform float mixValue;

void main() {
    // FragColor = vec4(ourColor, 1.0);
    FragColor = mix(texture(texture1, TexCoord), texture(texture2, TexCoord), mixValue);
}