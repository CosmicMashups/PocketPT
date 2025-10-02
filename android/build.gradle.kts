buildscript {
    val kotlinVersion by extra("1.9.10")
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.google.gms:google-services:4.3.15")
        classpath("com.android.tools.build:gradle:8.4.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Optional: Adjust build directory for your structure
// if (project.name == "app") {
//     val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
//     rootProject.layout.buildDirectory.value(newBuildDir)

//     subprojects {
//         if (project.name == "app") {
//             val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
//             project.layout.buildDirectory.value(newSubprojectBuildDir)
//         }
//     }
// }

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
