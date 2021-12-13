# Introduction 

Toyota Wallet Android is one of Nimble's client project in partnership with Toyota client. This note will summarize the finding from studying Toyota Wallet's source code and then it will highlight the pros and cons of the technical decisions within the application.

# Prerequisite

Before proceeding with this article or download and running Toyota Wallet Android source code, make sure you are comfortable with:

- Kotlin and Android OS lifecycle.
- Dependancy Injection with viewModel factory and custom scopes (Dagger2).
- MVVM with Clean Architecture.
- Crypto and Security APIs (KeyStore).
- Biometric that provides system information related to biometrics such as: fingerprint, face, etc. (BiometricManager).
- Reactive programming (RxJava).

# Installation

**Checkout this repository:**

`$ git clone git@github.com:nimblehq/toyota-wallet-android.git`

Open Android Studio -> Open Project -> Choose the path where the repository is checked out.

**Choose Build/Run from the GUI or use the command line:**

`$ ./gradlew assembleStagingDebug` 

```
⚠️ A small note: This command is not working properly on version `4.0.1`. As a result, we will need to upgrade the Android Gradle Plugin in this project (toyota-wallet-android) to the latest version, potentially `7.0.3`.
```

**Setup the Codestyle:**

From Android Studio: AS → Preferences → Code Style → Scheme (Click on the settings icon) → Import Scheme -> navigate to `config/codestyle.xml` -> select Open and OK to apply the selected Scheme.

![Screen Shot 2021-12-29 at 16 16 45](https://user-images.githubusercontent.com/70877098/147646387-f3a6b77c-8adb-4e69-8cab-c8d3f85bc2ba.png)


# Application Architecture

Taking a general view on the Toyota Wallet Android application, we can see that the files structure of the project is being organized into `Modules`. We have 3 main modules that contains all the required code for the application: `app`, `data` and `domain`. Besides that, we have another module - `common-rx` in the project but it seems to be redundant as there is no usage found for the classes inside this module. As a result, it is safe for us to ignore this module from the code analysis.

This project's modules organization is actually the reassembly of the layers of `MVVM with Clean Architecture` that the `app` module is the `Presentation` layer, the `data` module is a customized version of the `Data` layer and lastly the `domain` module is another customization version of the `Domain` layer. The detail about the differences of the customizations versions on the `data` and `domain` module will be clarified in their corresponding sections. The following diagram represents a quick look on the standard architecture for the project:

![MVVM Clean architecture](https://user-images.githubusercontent.com/70877098/147942090-21da70d1-787f-4c8b-b41b-46224decfc2a.jpeg)

With this architecture, the project can certainly take the benefits from itself such as: 
- Easily testable.
- Better decoupled.
- Easy to navigate the package structure.
- Simpler to maintain.
- Quicker to add new features.

As we all may know, each module will have an associated build.gradle file, tests folder and their main classes. Now, let's take a closer brief into each module:

## App Module

This module is basically the `Presentation` layer of the project that contains all the Views including Activities + Fragments and their corresponding ViewModels.

It is noticable that this project is following the Single Activity Design and to take full advantage of the [Navigation component](https://developer.android.com/guide/navigation/navigation-migrate), which is an official-standard solution from Google, that is used for navigating between screens declared in a multi-module project setup. There are 2 major Activities in the project: `OnboardingActivity` and `MainActivity`. 

### Activities

As the names of these activities stated, the `OnboardingActivity` is for handling the navigation flows and fragments before completing the authentication proccess (such as login or signup) with the entrance view is the `Splash` fragment. Some examples of the fragments in this onboarding navigation can be: Splash, Login, OTP, Pin, Terms & Conditions, etc. Here is an overview graph of the `Onboarding` navigation:

![Screen Shot 2021-12-29 at 15 05 07](https://user-images.githubusercontent.com/70877098/147640515-2bbf6b0a-8003-41e8-9174-918fac365dbb.png)


With the `MainActivity`, it will manage the navigations and fragments that contain all the main features of the application that users can access after the authentication. The project is quite huge and thus we can't list all the fragments out. The entrance view for this main navigation is the `Home` fragment. This is an overview graph of the `Main` navigation:

![Screen Shot 2021-12-29 at 15 20 24](https://user-images.githubusercontent.com/70877098/147645278-be9b3bb6-191a-49dd-8ec0-bcc561f7971e.png)

### Dependency Injections (DI)

Currently, the app uses purely Dagger for DI in the project and does not use the latest Hilt integration. Looking at the code, there are multiple custom scopes created and used within the application:

```kotlin
import javax.inject.Scope

@Scope
annotation class ApplicationScope

@Scope
annotation class ActivityScope

@Scope
annotation class FragmentScope

@Scope
annotation class DeepNestedFragmentScope

@Scope
annotation class NestedFragmentScope

@Scope
annotation class ServiceScope
```

As the name of the scope stated, each object injection will have its own scope associated with  and its life cycle depends on the usage need such as `ApplicationScope`, `ActivityScope`, `FragmentScope`, etc.

Exploring further, the Dependency Injections applicable area in this project is quite large that it spans on several layers, including:
- **Views:** contains mostly Fragments and Activities injections.
- **App:** contains the main Application Context and the singleton SchedulerProvider.
- **Services:** contains both authenticated + non-authenticated services and the authentication services for handling all the different backend's feature endpoints.
- **Auth:** contains mainly persistent storages with the session manager and an encryptor for handling user local authentication session on the phone, making sure it is cached and refreshed safely and securely.
- **Other:** contains all other remaining supporting injections in the application like: App Component, Glide, DaggerFraggment, etc.

### Extensions

This module has plenty of extensions files that are organized into each class extension per file. The type of extensions are quite abundant, ranging from basic UI Android components like: `ActivityExt`, `ContextExt`, `ViewExt`, etc. to core and reactive components like: `LocalDateTimeExt`, `NumberExt`, `RxViewExt`, `ObservableExt` etc. 

Unfortunately, the file naming of these extension doesn't seem to be consistent as sometime the postfix is `Ext` but sometime it is also written fully out to `Extension`:

![Screen Shot 2022-01-02 at 15 04 55](https://user-images.githubusercontent.com/70877098/147869818-f0480615-95b4-4af6-86f5-ddd0728f9246.png)

Apart from that, some extension files are named incorrectly comparing to the actual classes that they extend from. For example, `NavigationExt` is the file name but the class that is being extended is `FragmentActivity`:

![Screen Shot 2022-01-02 at 15 06 12](https://user-images.githubusercontent.com/70877098/147869863-f29bba72-cc3b-4af9-984b-d9e06e506145.png)

### Managers & Services

The services and managers from this module actually do not relate to the data layer where they will connect with the application's backend endpoints but instead they are the additional services classes that act as the interface for working with some 3rd-party libraries that are being used in the application or just simple helper services such as: 
- **BarcodeService**: generates a QR code using `BarcodeEncoder` from [ZXing Android Embedded](https://github.com/journeyapps/zxing-android-embedded).
- **BiometricService**: setups and shows a biometric prompt on screen when requested with the native [Android Biometric library](https://developer.android.com/jetpack/androidx/releases/biometric).
- **FCMManager**: retrieves the token string associated with the firebase account after logging in for sending notifications via [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging).
- **ImageExporterService**: a helper service that handle images storage on the phone. Directory path can also be provided for specifying where to store the images.
- **OmiseService**: a very special service that connects to Omise Staging server to generate a token for testing with the real credit card + real money movement like the production server.

### Storage

There is only one main storage class in this module, which is `AuthSharedPreferences`. As the name of this storage stated, it is for storing authentication status like tokens, ids and device settings securely. Here are the data that `AuthSharedPreferences` supports to store at the moment as it conforms the `AuthStorage`:

```kotlin
// Supported objects storage
interface AuthStorage {
    var authStatus: AuthStatus

    var biometricSettings: BiometricSettings

    var isCameraPermissionRequested: Boolean
}

// Main keys that are stored directly into the SharedPreferences
class AuthSharedPreferences @Inject constructor(
    encryptor: Encryptor,
    context: Context
) : BaseEncryptedStorage(encryptor, context, PREFS_NAME), AuthStorage {

    private var accessToken: String?
        get() = get(ACCESS_TOKEN_KEY, prefs, encryptor)
        set(value) = set(ACCESS_TOKEN_KEY, value)

    private var refreshToken: String?
        get() = get(REFRESH_TOKEN_KEY, prefs, encryptor)
        set(value) = set(REFRESH_TOKEN_KEY, value)

    private var registrationToken: String?
        get() = get(REGISTRATION_TOKEN_KEY, prefs, encryptor)
        set(value) = set(REGISTRATION_TOKEN_KEY, value)

    private var registrationUid: String?
        get() = get(REGISTRATION_UID_KEY, prefs, encryptor)
        set(value) = set(REGISTRATION_UID_KEY, value)

    private var registrationScbUid: String?
        get() = get(REGISTRATION_SCB_UID_KEY, prefs, encryptor)
        set(value) = set(REGISTRATION_SCB_UID_KEY, value)

    private var tokenType: String?
        get() = get(TOKEN_TYPE_KEY, prefs, encryptor)
        set(value) = set(TOKEN_TYPE_KEY, value)

    private var settingsBiometricEnabled: Boolean?
        get() = get(SETTINGS_BIOMETRIC_ENABLED_KEY, prefs, encryptor)
        set(value) = set(SETTINGS_BIOMETRIC_ENABLED_KEY, value)

    private var settingsBiometricSavedPin: String?
        get() = get(SETTINGS_BIOMETRIC_SAVED_PIN_KEY, prefs, encryptor)
        set(value) = set(SETTINGS_BIOMETRIC_SAVED_PIN_KEY, value)

    private var requestedCameraPermission: Boolean
        get() = get(REQUESTED_CAMERA_PERMISSION_KEY, prefs, encryptor) ?: false
        set(value) = set(REQUESTED_CAMERA_PERMISSION_KEY, value)
}
```

This storage class uses the `Encryptor` class to handle the crypto-related operations like encrypting and decrypting. This is interesting because `Encryptor` class sounds like it can only do encryption part but it fact it can do both. As a result, maybe we can rename this class to `Cipher` for correct representation. 

### UI

This is the package that contains all the views and screens defined in the entire application. There are quite a few sub-packages that group certain views or handlers of the same type:
- **Base**: contains all the base classes that handle the shared behaviors of its type such as: `BaseActivity`, `BaseFragment`, `BaseViewModel`, `BaseNavigator`, etc.
- **Common**: contains multiple types of common classes like `Toaster`, `OnloadMoreListener` and `ItemClickable`.
- **CustomViews**: contains custom Android view components and custom constraint layouts that can ussually be reused muliple times in the xml file(s) of the application. Some examples can be: `CurrencyEditText`, `PaymentMethodDetailView`, `TitleBarView`, etc.
- **Helpers**: contains view-related extensions like supporting partially clickable text on TextView or Checkbox or edge-2-edge handling. These extensions can actually be combine into the [Extension](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#extensions) package above instead.
- **Screens**: contains all the screens that are seen in the navigation graphs above. At the same time, we have some common screens like `WebView` and `ResultFragment` that are used from both `Main` and `Onboarding` navigation graphs. Other screens are groups per Activity since we are using Single Activity Design in the application. Interestingly, there is a `StartFragment` that is only used in the `Onboarding` navigation but it is placed in the `Common` group. As a result, it can be brought to `Onboarding` group instead.
- **Widgets**: also contains custom Android view components and custom constraint layouts like **CustomViews** such as `BarcodeViewfinderView`, `CheckableConstraintLayout`, `CheckableImageView`, etc. These custom views can definitely be combined with the **CustomViews** sub-package.

There are also 2 additional files that don't seem to be relevant with this package:
- **ErrorMapping**: this is a `Throwable` extension that helps generate a user's readable message from the throwable -> can be moved to the [Extension](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#extensions) module instead.
- **LocalizedResources**: this looks like an utility class that can help the application get a string using a resource id -> can be moved to the [Util](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#util) module instead.

### Util

There are 2 main utilities in this module. The first one is a `CrashlyticsTree` class that overrides the `Timber.Tree()` for logging messages and at the same time record those messages to `Crashlytics` if the message's priority type is `Log.Error`. 

The second one is a `ReflectionHelpers` class that are used mainly in testings for accessing private fields and methods reflectively. The unique thing with this helper is that it is written in Java. Unfortunately, there are quite a few major disadvantages when using reflection and we should avoid using it in my opinion:
1. Fields and methods accessing is much slower than direct code and thus creating performance problem.
2. The use of reflection will make program internal logic super fuzzy since reflection bypasses the source code visibility, which will lead the maintenance problem.
3. It used to perform dependency resolution at runtime, leading to unexpected crashes if the name of the field or method is modified without updating the reflections.

## Data Module

This module has all the services which the Domain layer can use and exposes the APIs to outside classes. By organizing it into the module, it can be shared and reused between projects as well, enhancing reusability when we need to connect to the same backend in different projects. 

At the same time, this Data module contains many supporting classes for those services such as a custom DateTime adapter for supporting JSON parsing, authenticator and interceptor for handling additional header params or token refreshing on each request, providers for generating necessary classes for Retrofit and OkHttp clients to work with via DI, request/response and error objects for each request, etc.

Interestingly, this current project doesn't strictly follow the [recommended architecture](https://developer.android.com/jetpack/guide#recommended-app-arch) from Android offical documents that all the repositories are being placed in the [Domain module](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#domain-module) instead. The following graph represents the Data module's classes that are being organized in the application at the moment:

![Data Layer Diagram](https://user-images.githubusercontent.com/70877098/147943038-5fb6b666-6c86-4d43-bd4e-6c713d530f4a.jpeg)

Addtionally, we have some other supporting classes like some reactive extensions for mapping errors to the stream, secrets and endpoint urls classes that contain some public information on the server side like urls, certificate hashes value for pinning, Omise server public key, etc.

## Domain Module

This module basically acts as the Domain layer which is responsible for encapsulating complex business logic, or simple business logic that is reused by multiple ViewModels from the Presentation layer. This layer is optional because not all apps will have these requirements. 

For this particular project, it is currently being structured as a separated module and thus it is considered as a needed layer since it can definitely help handle complexity + support reusability and testing. On top of that, each use case should only have responsibility over a single functionality, and they should not contain mutable data. It is suggested to handle mutable data in the UI or Data layers instead.

This module contains many use cases with their supporting classes such as data classes that are going to be sent to the viewModels from the use cases, different errors sealed classes that are going to be handled on the viewModels from the use cases, persistence and storage classes for handling and securing local data source on the phone, custom services interfaces that are used in the Presentation layer, etc.

Again, this current project is currently placing the repositories with some custom managers/services and local data persistences in this module instead of the [Data module](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#data-module). The following graph represents the Domain module's classes that are being organized in the application at the moment:

![Domain Layer diagram](https://user-images.githubusercontent.com/70877098/147952079-e5261b7d-cd2d-4c7a-bfd0-7f29128ab700.jpeg)

Last but not least, we have some other supporting classes like a `ContextExt` extension for getting the deviceId from `Context` class, and a `SchedulerProvider` for generating the corresponding scheduler for the use cases' returned observables to be subscribed and observed on.

# Proguard

The proguard rules are essential that helps make the application production-ready by shrinking code, removing unused code and thus reducing the application size. It also supports code obfuscation capability and make it harder to reverse-engineering the application. In this project, the `proguard-rules.pro` is only applied for the [App](https://github.com/minhnimble/learning-notes/blob/main/studied-projects/toyota-wallet-android.md#app-module) module:

```ruby
##---------------Begin: proguard configuration common for all Android apps ----------
-dontwarn org.slf4j**

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keepclassmembers class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}
-keep public class * implements android.os.Parcelable
##---------------End.

##---------------Begin: proguard configuration for Firebase Crashlytics  ----------
# Keep Crashlytics annotations
-keepattributes *Annotation*

# Keep file names/line numbers
-keepattributes SourceFile,LineNumberTable

# Keep custom exceptions
-keep public class * extends java.lang.Exception
##---------------End.

##---------------Begin: proguard configuration for Glide  ----------
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
 <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
  **[] $VALUES;
  public *;
}
##---------------End.

##---------------Begin: proguard configuration for retrofit ----------
# Retrofit does reflection on generic parameters. InnerClasses is required to use Signature and
# EnclosingMethod is required to use InnerClasses.
-keepattributes Signature, InnerClasses, EnclosingMethod

# Retrofit does reflection on method and parameter annotations.
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations

# Retain service method parameters when optimizing.
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}

# Ignore annotation used for build tooling.
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement

# Ignore JSR 305 annotations for embedding nullability information.
-dontwarn javax.annotation.**

# Guarded by a NoClassDefFoundError try/catch and only used when on the classpath.
-dontwarn kotlin.Unit

# Top-level functions that can only be used by Kotlin.
-dontwarn retrofit2.KotlinExtensions

# With R8 full mode, it sees no subtypes of Retrofit interfaces since they are created with a Proxy
# and replaces all potential values with null. Explicitly keeping the interfaces prevents this.
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
##---------------End.

##---------------Begin: proguard configuration for OkHttp ----------
# JSR 305 annotations are for embedding nullability information.
-dontwarn javax.annotation.**

# A resource is loaded with a relative path so the package of this class must be preserved.
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# Animal Sniffer compileOnly dependency to ensure APIs are compatible with older versions of Java.
-dontwarn org.codehaus.mojo.animal_sniffer.*

# OkHttp platform used only on JVM and when Conscrypt dependency is available.
-dontwarn okhttp3.internal.platform.ConscryptPlatform
##---------------End.

##---------------Begin: proguard configuration for Gson  ----------
# Gson uses generic type information stored in a class file when working with fields. Proguard
# removes such information by default, so configure it to keep all of it.
-keepattributes Signature

# Gson specific classes
-keep class sun.misc.Unsafe { *; }
-keep class com.google.gson.** { *; }

# R8 compatibility https://r8.googlesource.com/r8/+/refs/heads/master/compatibility-faq.md
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
##---------------End.

##---------------Begin: proguard configuration For RxJava  ----------
-keepclassmembers class rx.internal.util.unsafe.*ArrayQueue*Field* {
   long producerIndex;
   long consumerIndex;
}

-keepclassmembers class rx.internal.util.unsafe.BaseLinkedQueueProducerNodeRef {
   long producerNode;
   long consumerNode;
}
##---------------End.

#---------------Begin: Omise SDK https://github.com/omise/omise-android#proguard-rules  ----------
-dontwarn okio.**
-dontwarn com.google.common.**
-dontwarn org.joda.time.**
-dontwarn javax.annotation.**
-dontwarn com.squareup.**
-keep class co.omise.android.models.** { *; }
-keepclassmembers class co.omise.android.api.Endpoint {
   static ** VAULT;
}
##---------------End.

##---------------Begin: proguard config for Navigation Component
-keep class androidx.navigation.fragment.NavHostFragment{ *; }
##---------------End.
```

From the above proguard rules, we can see that the application uses different types of `keep` options as it needs to access certain classes, classmembers, names and attributes from the code. Mainly we want to keep because the application needs accesses them through reflection, or Proguard removes wrong items that could cause the app to crash, or if we want to preserve some compilation/debugging information.

At the same time, we can see quite a few `dontwarn` option usages as well. This option means that if there is an unresolved reference for a particular global pattern or if there's some warnings generated for these items, do not warn. This option is similar with `ignorewarnings` option as well.

# Reactive Programming

This project embraces the use of Reactive Programming with `RxJava` through out the application. The project includes three main libraries for Reactive Programming: 
- [RxAndroid: Reactive Extensions for Android](https://github.com/ReactiveX/RxAndroid)
- [RxJava2 Adapter](https://github.com/square/retrofit/tree/master/retrofit-adapters/rxjava2)
- [RxBinding](https://github.com/JakeWharton/RxBinding)

Looking for a common example of reactive programing techniques on handling observables, we can start by having a look on the `HomeFragment` from the View layer:

- UI events binding to a viewModel's input that when user click on the toolbar's avatar, it will navigate users to the profile screen:
```kotlin
private fun setupToolbar() {
    toolbar?.run {
        ivToolbarAvatar.visible()
        ivToolbarAvatar
            .subscribeOnClick(viewModel::navigateToProfile)
            .addToDisposables()
    }
 }
```

- viewModel's observables output subscriptions for handling data events triggered from viewModels and update UI display accordingly:
```kotlin
override fun bindViewModel() {
    super.bindViewModel()
    viewModel.profile bindTo ::bindProfile
    viewModel.hasScbPrivacyNoticeUpdated bindTo { showScbPrivacyNoticeUpdatedDialog() }
}
```

Reaching to the ViewModel layer, we can see that the `HomeViewModel` uses the use cases that returns observables instead of working with repositories or services directly:

```kotlin
class HomeViewModelImpl @Inject constructor(
    checkAppVersionForUpdateUseCase: CheckAppVersionForUpdateUseCase,
    getDeviceLocaleUseCase: GetDeviceLocaleUseCase,
    getAuthStatusUseCase: GetAuthStatusUseCase,
    getCampaignUseCase: GetCampaignUseCase,
    private val localizedResources: LocalizedResources,
    private val getWalletBalanceUseCase: GetWalletBalanceUseCase,
    private val getProfileUseCase: GetProfileUseCase,
    private val getUserPersistenceUseCase: GetUserPersistenceUseCase,
    private val updateUserPersistenceUseCase: UpdateUserPersistenceUseCase,
    private val requestScbAuthorizeUseCase: RequestScbAuthorizeUseCase,
    private val isAppUnlockedUseCase: IsAppUnlockedUseCase,
    private val getUpdatedAgreementsUseCase: GetUpdatedAgreementsUseCase,
    private val acceptDeclineAgreementUseCase: AcceptDeclineAgreementUseCase
) : HomeViewModel(
    checkAppVersionForUpdateUseCase,
    getDeviceLocaleUseCase,
    getAuthStatusUseCase,
    getCampaignUseCase
)
```

- A typical usage of a use case in this viewModel that the application accepts or declines the agreement that the observables handle different flows for success and error cases and we can inject to show a loading indicator when the stream is triggered:
```kotlin
override fun acceptDeclineAgreement(accepted: Boolean) {
    acceptDeclineAgreementUseCase
        .execute(
            AcceptDeclineAgreementUseCase.Input(
                updatedAgreements.orEmpty(),
                accepted
            )
        )
        .doShowLoading()
        .subscribeBy(
            onSuccess = {
                updatedAgreements = it
                navigateToUserAgreementReview()
            },
            onError = _error::onNext
        )
        .addToDisposables()
}
```

At the UseCase layer, `AcceptDeclineAgreementUseCase` connects with the `UserRepository` produce a `Single`. It behaves the same as Observable except that it can only emit either a single successful value, or an error (there is no "onComplete" notification as there is for Observable).

```kotlin
class AcceptDeclineAgreementUseCase @Inject constructor(
    schedulerProvider: BaseSchedulerProvider,
    private val repository: UserRepository
) : SingleUseCase<AcceptDeclineAgreementUseCase.Input, List<Agreement>>(
    schedulerProvider.io(),
    schedulerProvider.main(),
    ::AcceptDeclineAgreementError
) {

    data class Input(
        val agreements: List<Agreement>,
        val accepted: Boolean
    )

    override fun create(input: Input): Single<List<Agreement>> {
        return with(input) {
            repository.acceptDeclineAgreement(
                agreements.firstOrNull()?.uid.orEmpty(),
                if (accepted) USER_AGREEMENT_STATUS_ACCEPTED else USER_AGREEMENT_STATUS_DECLINED
            ).toSingle {
                agreements.toMutableList().also {
                    it.removeFirstOrNull()
                }
            }
        }
    }
}
```

In the Repository layer, `UserRepository` actually calls to an endpoint of the `UserService` that we don't care about the response payload at this point, thus a Completable is returned for the stream here to represent a deferred computation without any value but only indication for completion or exception.

```kotlin
override fun acceptDeclineAgreement(
    uid: String,
    status: String
): Completable {
    val request = AcceptDeclineAgreementRequest(uid, status)
    return service
        .acceptDeclineAgreement(request)
        .transform()
        .toCompletable()
}
```

Finally, in the Service layer, `UserService` handles an empty response for this `user_agreements` endpoint, which explains why we don't need to parse the response in the Repository layer.

```kotlin
@POST("user_agreements")
fun acceptDeclineAgreement(
    @Body request: AcceptDeclineAgreementRequest
): Single<Response<EmptyResponse>>
```

# Points of Interest

## ScanCardActivity

Unlike normal projects with 2 Activities at max with their corresponding navigation graphs for Single Activity Architecture design, this project has another activity - `ScanCardActivity` that it doesn't have its own navigation graph. This activity is basically used as an overlay to implement the scan card function that appears on the top of the `MainActivity` and it inherits a base class from a 3rd-party library - [cards.pay.paycardsrecognizer](https://github.com/faceterteam/PayCards_Android) to handle the automatic recognition of bank card data using built-in camera scanning functionality.


```kotlin
class ScanCardActivity : BaseScanCardActivity() {

    private val fragmentLifecycleCallBack = object : FragmentManager.FragmentLifecycleCallbacks() {
        override fun onFragmentViewCreated(
            fragmentManager: FragmentManager,
            fragment: Fragment,
            view: View,
            savedInstanceState: Bundle?
        ) {
            super.onFragmentViewCreated(fragmentManager, fragment, view, savedInstanceState)

            if (fragment is InitLibraryFragment || fragment is ScanCardFragment) {
                setWindowStyle()
                val ivScanBack = findViewById<View>(R.id.ivScanBack)
                ivScanBack.setOnClickListener {
                    setResult(RESULT_CANCELED)
                    finish()
                }
                findViewById<View>(R.id.clScanToolbar).handlingVisualOverlaps(
                    gravity = Gravity.TOP,
                    forceInsetsApplying = true
                )
            }
        }
    }

    // Setup code
    // ...
}
```

=> This is quite an interesting choice since it is now only presented from the `ScanCardFragment` from the Main navigation graph. It is probably because the View for scanning the card from the library is an Activity. It would be ideal for Single Activity Design if the application use a fragment here instead and there is a library that can support that.

## ViewModelFactory

Since we are using purely Dagger for Dependency Injection, `ViewModelFactory` is created and it conforms the `ViewModelProvider.Factory` interface so that it can be used to create a ViewModel object when the project needs. Interestingly, with the custom scopes the application has, the corresponding UI factories can be easily created based on those scopes such as: `ActivityViewModelFactory`, `FragmentViewModelFactory`, `NestedFragmentViewModelFactory`, etc.

```kotlin
open class ViewModelFactory(
    private val creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelProvider.Factory {

    override fun <T : ViewModel> create(modelClass: Class<T>): T {
        var creator: Provider<out ViewModel>? = creators[modelClass]
        if (creator == null) {
            for (entry in creators.entries) {
                if (modelClass.isAssignableFrom(entry.key)) {
                    creator = entry.value
                    break
                }
            }
        }
        requireNotNull(creator) { "unknown model class $modelClass" }

        try {
            return creator.get() as T
        } catch (e: Exception) {
            throw RuntimeException(e)
        }
    }
}

@ActivityScope
class ActivityViewModelFactory @Inject constructor(
    creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelFactory(creators)

@FragmentScope
class FragmentViewModelFactory @Inject constructor(
    creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelFactory(creators)

@NestedFragmentScope
class NestedFragmentViewModelFactory @Inject constructor(
    creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelFactory(creators)

class DeepNestedFragmentViewModelFactory @Inject constructor(
    creators: Map<Class<out ViewModel>, @JvmSuppressWildcards Provider<ViewModel>>
) : ViewModelFactory(creators)

```

=> It would be better to use Hilt that can help reduce the boilerplate of doing manual dependency injection in this project by providing containers for every Android class in your project and managing their lifecycles automatically. As a result, the factory code and the custom scopes above can be removed since Hilt already has [Hilt components](https://developer.android.com/training/dependency-injection/hilt-android#generated-components) to support injecting its bindings into the corresponding Android class with the according [Component scopes](https://developer.android.com/training/dependency-injection/hilt-android#component-scopes).

## Encryption

It is noticable that the project uses encryption techniques for protecting data stored on the device like tokens, uids and device settings (biometric, camera permission, etc.). To achieve that, in the project we have 2 files for handling the security, which are: `AuthSecretKey` and `Encryptor`.

`AuthSecretkey` is basically a key generator interface that uses the `KeyStore` API to create a random `SecretKey` object that contains information about a private key that can be used for a specific encryption algorithm, in this case it would be AES128 with block mode - GCM and encryption paddings - none. There is also a class `PreMAuthSecretKeyImpl` that contains a hard-coded private key but it doesn't seem to be used in the application.

```kotlin
private fun createKeyEntry() {
    val keyGenerator = KeyGenerator.getInstance(KEY_ALGORITHM_AES, KEY_STORE_NAME)
    val purposes = PURPOSE_ENCRYPT or PURPOSE_DECRYPT
    val spec = KeyGenParameterSpec.Builder(KEY_STORE_ALIAS, purposes)
        .setBlockModes(BLOCK_MODE_GCM)
        .setEncryptionPaddings(ENCRYPTION_PADDING_NONE)
        .setRandomizedEncryptionRequired(false)
        .build()
    keyGenerator.init(spec)
    keyGenerator.generateKey()
}
```

`Encryptor` is the interface that will be use throughout the application to encrypt/decrypt the actual data using the generated private key from `AuthSecretkey`. The `Encryptor` is mostly used in the `AuthSharedPreferences` where the application stores the user session data locally. The `Encryptor` can basically get the `SecretKey` object and create a cipher depending on the purpose (encrypt or decrypt) and handle the data accordingly.

```kotlin
class EncryptorImpl @Inject constructor(
    private val secretKey: AuthSecretKey
) : Encryptor {

    override fun encryptAndEncode(unencrypted: String): String {
        val cipher = getCipher(Cipher.ENCRYPT_MODE)
        val encryptedData = cipher.doFinal(unencrypted.toByteArray(Charsets.UTF_8))
        return Base64.encodeToString(encryptedData, Base64.NO_WRAP)
    }

    override fun decodeAndDecrypt(encoded: String): String {
        val cipher = getCipher(Cipher.DECRYPT_MODE)
        val encryptedBytes = Base64.decode(encoded, Base64.NO_WRAP)
        val decryptedBytes = cipher.doFinal(encryptedBytes)
        return String(decryptedBytes, Charsets.UTF_8)
    }

    private fun getCipher(mode: Int): Cipher {
        return Cipher.getInstance(TRANSFORMATION).apply {
            val spec = GCMParameterSpec(AUTHENTICATION_TAG_LENGTH, ENCRYPTION_IV)
            init(mode, secretKey.get(), spec)
        }
    }
}
```

=> As of now, the AES encryption algorithm can be considered safe as per [this discussion](https://www.kryptall.com/index.php/2015-09-24-06-28-54/how-safe-is-safe-is-aes-encryption-safe) but the key generation seems to happen only once after a fresh application install with the current logic. As a result, a key rotation mechanism like adding a key rotation period logic can be deployed and applied for a better security protection.

## BaseEncryptedStorage

The `BaseEncryptedStorage` class is created and used only for the `AuthSharedPreferences` class that contains two main operations: get the encrypted data from and set the decrypted data on a private `SharedPreferences`:

```kotlin
abstract class BaseEncryptedStorage(
    protected val encryptor: Encryptor,
    context: Context,
    prefsName: String
) {

    protected val prefs: SharedPreferences =
        context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)

    protected inline fun <reified T> get(
        key: String,
        prefs: SharedPreferences,
        encryptorInline: Encryptor
    ): T? {
        val rawValue = prefs.getString(encryptorInline.encryptAndEncode(key), null)
        return if (rawValue != null) {
            val value = try {
                encryptorInline.decodeAndDecrypt(rawValue)
            } catch (e: SecretKeyException) {
                // Remove the item from preferences as it cannot be decrypted any more
                set(key, null)
                null
            }
            when (T::class) {
                String::class -> value as T?
                Boolean::class -> value.toBoolean() as T?
                Float::class -> value?.toFloat() as T?
                Int::class -> value?.toInt() as T?
                Long::class -> value?.toLong() as T?
                else -> null
            }
        } else {
            null
        }
    }

    protected fun <T> set(key: String, value: T?) {
        prefs.edit {
            when (value) {
                null -> remove(encryptor.encryptAndEncode(key))
                else -> {
                    putString(
                        encryptor.encryptAndEncode(key),
                        encryptor.encryptAndEncode(value.toString())
                    )
                }
            }
        }
    }
}
```

=> This seems to be a pre-handling action and it contributes no value at the moment since the base class (parent class) has only one child class. These type of future-handling actions will probably cause development effort to be bigger and they will consume more time to develop a certain feature unnecessarily. In fact, maybe we can simply write these two functions directly into the `AuthSharedPreferences` as private functions until there is actually a need for having a base class.

## GcpfApplication

There is a quite interesting technique used in the application to stop the current activity if the account is locked or application force upgrade using the check from `AppPersistence`: 

```kotlin
class GcpfApplication : DaggerApplication() {
	// ..
	inner class AccountLockingActivityLifecycle : ActivityLifecycleCallbacks {

		// ..

        override fun onActivityStarted(activity: Activity) {
            if (activity !is MainActivity) {
                appPersistence
                    .accountLockedOrForceUpgrade
                    .filter { (locked, activityRef) -> locked && activityRef?.get() != activity }
                    .subscribe {
                        activity.finish()
                    }
                    .addToDisposables()
            }
        }

        // ..
    }
}
```

=> Unfortunately, the check seems to only verify if the current activity is not `MainActivity`, which can be the remaining two activities `OnboardingActivity` or `ScanCardActivity`. As a result, it is actually quite confusing here and probably can cause some bugs that the application's stop trigger doesn't work properly if somehow the current activity is `ScanCardActivity` and the observable event triggers at this point, because `ScanCardActivity` is presented from `MainActivity` so stopping `ScanCardActivity` will just show the `MainActivity` back and user still can use the application normally.

## View Binding

From the `HomeFragment` example, we can see that the application still uses synthetics instead of Jetpack view binding:

```kotlin
import co.omise.gcpf.app.R
import co.omise.gcpf.app.extension.subscribeOnClick
import co.omise.gcpf.app.extension.visible
import co.omise.gcpf.app.ui.base.PRIORITY_LINK_BANK_ACCOUNT
import co.omise.gcpf.app.ui.base.PRIORITY_UPDATED_AGREEMENTS
import co.omise.gcpf.app.ui.helpers.handlingVisualOverlaps
import co.omise.gcpf.app.ui.screens.main.profile.ProfileUiModel
import com.google.android.material.dialog.MaterialAlertDialogBuilder
import kotlinx.android.synthetic.main.fragment_home.*
import kotlinx.android.synthetic.main.toolbar_home.view.*

class HomeFragment : BaseHomeFragment<HomeViewModel>() {

    override val viewModelClass = HomeViewModel::class

    override fun setupView() {
        super.setupView()
        setupToolbar()
    }

    // More code
    // ..
}
```

=> This is a warning concern as Kotlin Android Extensions is deprecated, which means that using Kotlin synthetics for view binding will be no longer supported. As a result, it is recommended for us to update the application and use Jetpack view binding instead. Here is an example [guide](https://developer.android.com/topic/libraries/view-binding/migration) for handling the migration from Kotlin synthetics to Jetpack view binding.

## JSON Parser Selection

Currently, this application is using [Gson](https://github.com/google/gson) to convert objects into their JSON representation.

```kotlin
// Retrofit provider
internal object RetrofitProvider {
	// Existing code
	// ..
	private fun assembleRetrofit(
        context: Context,
        apiEndpointUrl: String,
        authenticationType: AuthenticationType,
        sessionManager: SessionManager,
        tokenRefresher: TokenRefresher?
    ): Retrofit {
        val okHttpClient =
            provideOkHttpClient(context, authenticationType, sessionManager, tokenRefresher)
        val gson = GsonProvider.gsonBuilder.create()
        val converters = provideConverters(gson)
        return provideRetrofitBuilder(apiEndpointUrl, okHttpClient, *converters).build()
    }
}

// Gson provider
internal object GsonProvider {

    val gsonBuilder: GsonBuilder
        get() = GsonBuilder().apply {
            registerTypeAdapter(LocalDateTime::class.java, DateTimeTypeAdapter())
        }
}

```

=> We could optimize to use the best JSON parser - [Moshi](https://github.com/square/moshi) for this project as per our analyis from this [RFC](https://github.com/nimblehq/compass/issues/437) on the best JSON parser we should choose for future projects from now on.

# Conclusion

Toyota Wallet Android is a medium-size app with around 3 mins of build time. The source code is quite interesting to study. The project basically follows the MVVM with Clean Architure to keep to the heart of Android natively supported components and it is delivered quite well with just some customizations on the `Data` and `Domain` layers there that can be optimized more. In the end, this architecture is one of the best and most scalable architectures for Android apps.

The project contains quite decent amount of tests (1033 test cases for the `app` module, 356 test cases for the `domain` module and 69 test cases for the `data` module) which could reflect how easy the testability the project has. Most views are independent of each other and the view models for each views are created accordingly which further reduces their dependencies. The project does use a lot of 3rd party libraries which can be seen from the `.gradle` files and they are mostly the popular ones in Android development like Retrofit, RxJava, Gson, Dagger, Firebase, etc.

As mentioned above in `Points of Interest` section, there are plenty of refactors and improvements can be made to further enhancing the project's code organization, consistency and security. Nevertheless, it is very interesting project that there are plenty of great and latest techniques in there to learn from.
