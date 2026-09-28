{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            androidComposition =
                                pkgs.androidenv.composeAndroidPackages
                                    {
                                        platformVersions = [ "35" ] ;
                                        buildToolsVersions = [ "35.0.0" ] ;
                                        includeEmulator = true ;
                                        includeSystemImages = true ;
                                        systemImageTypes = [ "google_apis" ] ;
                                        abiVersions = [ "x86_64" ] ;
                                    } ;
                            androidSdk = androidComposition.androidsdk ;
                            implementation =
                                { config , lib , pkgs , ... } :
                                    {
                                        options.android-application =
                                            {
                                                build = null ;
                                                fetch =
                                                    lib.mkOption
                                                        {
                                                            default =
                                                                pkgs.writeShellApplication
                                                                    {
                                                                        name = "download" ;
                                                                        runtimeInputs =
                                                                            [
                                                                                pkgs.coreutils
                                                                                pkgs.findutils
                                                                                pkgs.gradle
                                                                                pkgs.gnutar
                                                                                ( failure 5292191918653840 )
                                                                                androidSdk
                                                                                (
                                                                                    pkgs.writeShellApplication
                                                                                        {
                                                                                            name = "explode" ;
                                                                                            runtimeInputs =
                                                                                                [
                                                                                                    pkgs.coreutils
                                                                                                    pkgs.git
                                                                                                    pkgs.jdk
                                                                                                    ( failure 4967196713656753 )
                                                                                                ] ;
                                                                                            text =
                                                                                                ''
                                                                                                    RELATIVE_FILE="$1"
                                                                                                    ABSOLUTE_FILE="$( realpath "$RELATIVE_FILE" )" || failure 7667864193624809
                                                                                                    ABSOLUTE_DIRECTORY="$ABSOLUTE_FILE.exploded"
                                                                                                    mkdir --parents "$ABSOLUTE_DIRECTORY"
                                                                                                    cd "$ABSOLUTE_DIRECTORY"
                                                                                                    split --bytes=10M "$ABSOLUTE_FILE"
                                                                                                    git add "$ABSOLUTE_DIRECTORY"
                                                                                                    rm "$ABSOLUTE_FILE"
                                                                                                '' ;
                                                                                        }
                                                                                )
                                                                                (
                                                                                    pkgs.writeShellApplication
                                                                                        {
                                                                                            name = "cleanup" ;
                                                                                            runtimeInputs = [ pkgs.coreutils ] ;
                                                                                            text =
                                                                                                ''
                                                                                                    rm --recursive --force "$GRADLE_USER_HOME"
                                                                                                '' ;
                                                                                        }
                                                                                )
                                                                            ] ;
                                                                        text =
                                                                            ''
                                                                                export ANDROID_HOME=${ androidSdk }
                                                                                cd frontend/mobile
                                                                                GRADLE_USER_HOME="$(mktemp --directory)" || failure 6182679945594691
                                                                                export GRADLE_USER_HOME
                                                                                trap cleanup EXIT

                                                                                gradle \
                                                                                    -Pandroid.aapt2FromMavenOverride="$ANDROID_HOME/libexec/android-sdk/build-tools/35.0.0/aapt2" \
                                                                                    build
                                                                                rm --recursive --force gradle-dependencies
                                                                                cp --recursive "$GRADLE_USER_HOME/caches/." gradle-dependencies/
                                                                                find gradle-dependencies \
                                                                                    -type f \
                                                                                    \( -name '*.lock' -o -name 'gc.properties' \) \
                                                                                    -delete
                                                                                echo 1723258852938545 4247271882821595
                                                                                find gradle-dependencies -type f -name "*.jar" -print -exec explode {} \;
                                                                                echo 1723258852938545 2282220072447790
                                                                                find gradle-dependencies -type f -name "*.jar" -exec failure 7242237646954809 \;
                                                                                chmod --recursive a+rwX gradle-dependencies
                                                                                git add gradle-dependencies
                                                                                rm --recursive --force .gradle
                                                                                git clean -fd
                                                                                git commit -m "$1" --allow-empty-message
                                                                            '' ;
                                                                    } ;
                                                                type = lib.types.package ;
                                                        } ;
                                            } ;
                                } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}