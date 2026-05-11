import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.app.tahseen.dev"
            resValue(type = "string", name = "app_name", value = "Tahseen [DEV]")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.app.tahseen.tahseen"
            resValue(type = "string", name = "app_name", value = "Tahseen")
        }
    }
}