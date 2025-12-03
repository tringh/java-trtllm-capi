plugins {
    id("java")
    `maven-publish`
}

group = "io.github.tringh.jallama"
version = "0.0.1"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(25))
    }
}

sourceSets {
    main {
        java {
            srcDir(
                "${project.layout.buildDirectory.get().asFile}/generated/jextract")
        }
    }
}


repositories {
    mavenCentral()
}

tasks.register<Exec>("compileNative") {
    group = "build"
    description = "Compile core library"
    workingDir = layout.projectDirectory.dir("scripts").asFile
    commandLine("bash", "./build_corelib.sh")
    standardOutput = System.out
}

tasks.register<Exec>("generateBindings") {
    group = "build"
    description = "Run Jextract"
    dependsOn("compileNative")
    workingDir = layout.projectDirectory.dir("scripts").asFile
    commandLine("bash", "./jextract.sh")
    standardOutput = System.out
}

tasks.named("compileJava") {
    dependsOn("generateBindings")
}

tasks.withType<Test> {
    // Preload libjsig.so to prevent the Signal Handler conflict (MPI vs JVM)
    environment("LD_PRELOAD", "/usr/lib/jvm/jdk-25.0.1-oracle-x64/lib/libjsig.so")

    val trtllmCapiPath = rootProject.projectDir
        .resolve("core/build/libtrtllm_capi.so")
        .absolutePath
    environment("LIB_TRTLLM_CAPI", trtllmCapiPath)

    // Pass through important native environment variables
    val libraryPath = System.getenv("LD_LIBRARY_PATH")
    if (libraryPath != null) {
        environment("LD_LIBRARY_PATH", libraryPath)
    }

    // Enable native access
    jvmArgs("--enable-native-access=ALL-UNNAMED")
}

dependencies {
    testImplementation(platform("org.junit:junit-bom:5.10.0"))
    testImplementation("org.junit.jupiter:junit-jupiter")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")
}

tasks.test {
    useJUnitPlatform()
}

publishing {
    publications {
        create<MavenPublication>("mavenJava") {
            from(components["java"])
        }

        repositories {
            maven {
                name = "GithubPackages"
                url = uri("https://maven.pkg.github.com/tringh/java-trtllm-capi")

                credentials {
                    username = project.findProperty("gpr.user") as String? ?: System.getenv("GITHUB_ACTOR")
                    password = project.findProperty("gpr.key") as String? ?: System.getenv("GITHUB_TOKEN")
                }
            }
        }
    }
}