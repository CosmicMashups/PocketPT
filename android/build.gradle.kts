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

// Keep Gradle outputs under <project-root>/build so Flutter tooling can find APKs.
rootProject.buildDir = file("../build")

subprojects {
    buildDir = rootProject.buildDir.resolve(name)
}

subprojects {
    evaluationDependsOn(":app")
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
