# react-native-wikitude

## Install / Configure

Install and Link:

```sh
npm install --save monkeybreadtech/react-native-wikitude
react-native link
```

### iOS

Add a line to your Podfile to include the provided pod:
```sh
[...]
pod 'RNWikitude', :path => '../node_modules/react-native-wikitude/ios'
[...]
```

Then, from your `ios` folder, run `pod install`.

Finally, navigate to your Project file, open the Build Phases tab, and in the Link Binary With Libraries section, click the plus button and add the libRNWikitude.a library to the project.

### Android

Copy `wikitudesdk.aar` from `node_modules/react-native-wikitude/android/libs/` to `android/libs/`:

```sh
mkdir -p android/app/libs
cp node_modules/react-native-wikitude/android/libs/wikitudesdk.aar android/app/libs/
```

In your top-level build.gradle, add a 'flatDir' attribute to the repositories section:
```
allprojects {
    repositories {
        [...]
        // ADD THE NEXT THREE LINES
        flatDir {
            dirs 'libs'
        }
    }
}
```

In your app's build.gradle (i.e. `/android/app/build.gradle`), add this link near the existing reference to react-native-wikitude:

```sh
    [...]
    compile project(':react-native-wikitude')
    compile(name: 'wikitudesdk', ext: 'aar')
    [...]
```

Finally, in MainApplication.java, add the RNWikitudePackage:

```java
    [...]
    return Arrays.<ReactPackage>asList(
            [...]
            new RNWikitudePackage()
    );
    [...]
```

## Usage

Import the library:

```js
import Wikitude from 'react-native-wikitude';
```

In your `render()` method, use include a `<Wikitude />` component:

```js
render() {
  return (
    <Wikitude
      style={{flex: 1}}
      ref="wikitude"
      licenseKey="<licenseKey>"
      architectWorldURL="<URLToArchitectWorldFile"
    />
  );
}
```
