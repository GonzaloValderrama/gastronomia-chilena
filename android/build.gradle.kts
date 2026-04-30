allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

subprojects {
    project.configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "com.arthenica" && requested.name.startsWith("ffmpeg-kit")) {
                useTarget("com.mrljdx:ffmpeg-kit-full:6.1.4")
            }
        }
    }
}

rootProject.buildDir = layout.buildDirectory.asFile.get()
subprojects {
    project.buildDir = layout.buildDirectory.asFile.get()
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}