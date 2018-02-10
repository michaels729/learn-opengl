#version 430 core

#define NR_POINT_LIGHTS 4

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

struct DirLight {
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;
};

struct PointLight {    
    vec3 position;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;
};

struct SpotLight {    
    vec3 position;
    vec3 direction;

    vec3 ambient;
    vec3 diffuse;
    vec3 specular;

    float constant;
    float linear;
    float quadratic;

    float cutOff;
    float outerCutOff;
};

uniform bool blinn;

uniform Material material;
uniform DirLight dirLight;
uniform PointLight pointLights[NR_POINT_LIGHTS];
uniform SpotLight spotLight;

vec3 CalcSpecular(vec3 lightDir, vec3 normal, vec3 viewDir,
        float materialShininess, vec4 tex, vec3 lightSpecular,
        bool useBlinnPhong) {
    float spec;
    if (useBlinnPhong) {
        vec3 halfwayVec = normalize(lightDir + viewDir);
        spec = pow(max(dot(normal, halfwayVec), 0.0f), materialShininess * 2);
    } else {
        vec3 reflectDir = reflect(-lightDir, normal);
        spec = pow(max(dot(viewDir, reflectDir), 0.0f), materialShininess);
    }
    return vec3(tex) * spec * lightSpecular;
}

vec3 CalcDirLight(DirLight light, vec3 normal, vec3 viewDir) {
    vec3 lightDir = normalize(-light.direction);

    // ambient
    vec3 ambient = vec3(texture(material.diffuse, TexCoords)) * light.ambient;

    // diffuse
    float diff = max(dot(normal, lightDir), 0.0f);
    vec3 diffuse = diff * vec3(texture(material.diffuse, TexCoords)) * light.diffuse;

    // specular
    vec3 specular = CalcSpecular(lightDir, normal, viewDir, material.shininess,
            texture(material.specular, TexCoords), light.specular, blinn);

    return ambient + diffuse + specular;
}

vec3 CalcPointLight(PointLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    // attenuation
    float distance = length(light.position - fragPos);
    float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

    // ambient
    vec3 ambient = vec3(texture(material.diffuse, TexCoords)) * light.ambient * attenuation;

    // necessary light direction for diffuse and specular
    vec3 lightDir = normalize(light.position - fragPos);

    // diffuse
    float diff = max(dot(normal, lightDir), 0.0f);
    vec3 diffuse = diff * vec3(texture(material.diffuse, TexCoords)) * light.diffuse * attenuation;

    // specular
    vec3 specular = CalcSpecular(lightDir, normal, viewDir, material.shininess,
            texture(material.specular, TexCoords), light.specular, blinn) * attenuation;

    return ambient + diffuse + specular;
}

vec3 CalcSpotLight(SpotLight light, vec3 normal, vec3 fragPos, vec3 viewDir) {
    // attenuation
    float distance = length(light.position - fragPos);
    float attenuation = 1.0f / (light.constant + light.linear * distance + light.quadratic * distance * distance);

    // intensity
    vec3 lightDir = normalize(light.position - fragPos);
    float theta = dot(lightDir, normalize(-light.direction));
    float epsilon = light.cutOff - light.outerCutOff;
    float intensity = clamp((theta - light.outerCutOff) / epsilon, 0.0f, 1.0f);

    // ambient
    vec3 ambient = vec3(texture(material.diffuse, TexCoords)) * light.ambient * attenuation * intensity;

    // diffuse
    float diff = max(dot(normal, lightDir), 0.0f);
    vec3 diffuse = diff * vec3(texture(material.diffuse, TexCoords)) * light.diffuse * attenuation * intensity;

    // specular
    vec3 specular = CalcSpecular(lightDir, normal, viewDir, material.shininess,
            texture(material.specular, TexCoords), light.specular, blinn) * attenuation * intensity;

    return ambient + diffuse + specular;
}

void main() {
    vec3 norm = normalize(Normal);
    vec3 viewDir = normalize(viewPos - FragPos);

    vec3 result = CalcDirLight(dirLight, norm, viewDir);
    for (int i =  0; i < NR_POINT_LIGHTS; ++i) {
        result += CalcPointLight(pointLights[i], norm, FragPos, viewDir);
    }
    result += CalcSpotLight(spotLight, norm, FragPos, viewDir);

    FragColor = vec4(result, 1.0f);
}