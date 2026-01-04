// Kök dizindeki build.gradle.kts dosyanız

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Firebase ve Google Servisleri için gerekli classpath eklemesi
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Firebase entegrasyonu için bu satır eklendi
        classpath("com.google.gms:google-services:4.3.15")
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}