#version 430 core
in vec3 FragPos;
in vec3 Normal;
in vec2 TexCoords;

out vec4 FragColor;

uniform vec3 objectColor;
uniform vec3 lightColor;
uniform vec3 viewPos;

struct Material {
    sampler2D diffuse;
    sampler2D specular;
    float shininess;
};

struct Light {
    vec3 position;
    vec3 direction;
    float cutOff;
    float outerCutOff;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

uniform Material material;
uniform Light light;

void main() {
    vec3 lightDir = normalize(light.position - FragPos);

    float theta = dot(lightDir, normalize(-light.direction));
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0f, 1.0f);

    // ambient
    vec3 ambient = vec3(texture(material.diffuse, TexCoords)) * light.ambient * intensity;

    // Normalize normal vector for diffuse and specular
    vec3 norm = normalize(Normal);

    // diffuse
    float diff = max(dot(norm, lightDir), 0.0f);
    vec3 diffuse = diff * vec3(texture(material.diffuse, TexCoords)) * light.diffuse * intensity;

    // specular
    vec3 viewDir = normalize(viewPos - FragPos);
    vec3 reflectDir = reflect(-lightDir, norm);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0f), material.shininess);
    vec3 specular = vec3(texture(material.specular, TexCoords)) * spec * light.specular * intensity;

    vec3 result = ambient + diffuse + specular;
    FragColor = vec4(result, 1.0f);
}