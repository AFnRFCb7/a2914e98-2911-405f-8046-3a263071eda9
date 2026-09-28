{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { failure } :
                        let
                            implementation =
                                { config , lib , pkgs , ... } :
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
                                        in
                                            {
                                                options.android-application =
                                                    {
                                                        build = null  ;
                                                        fetch =
                                                            lib.mkOption
                                                                {
                                                                    default =
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "fetch" ;
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
                                                                                                            RELATIVE_INPUT_FILE="$1"
                                                                                                            ABSOLUTE_INPUT_FILE="$( realpath "$RELATIVE_FILE" )" || failure 7667864193624809
                                                                                                            HASH="$( echo "$RELATIVE_FILE" | sha512sum | cut --characters 1-128 )" || failure 4885129150129948
                                                                                                            mkdir --parents "gradle-dependencies.exploded/$HASH"
                                                                                                            cd gradle-dependencies.exploded/$HASH
                                                                                                            PERMISSIONS="$( stat --printf %a "$ABSOLUTE_INPUT_FILE" )" || failure 6903848712762824
                                                                                                            TYPE="$( stat %F "$ABSOLUTE_INPUT_FILE" )" || failure 9926977401820663
                                                                                                            jq \
                                                                                                                --null-input \
                                                                                                                --arg PERMISSIONS "$PERMISSIONS" \
                                                                                                                --arg TAG "$TAG" \
                                                                                                                --arg TYPE "$TYPE" \
                                                                                                                '{
                                                                                                                    "permissions" : $PERMISSIONS ,
                                                                                                                    "tag" : $TAG ,
                                                                                                                    "type" : $TYPE
                                                                                                                }' > metadata.json
                                                                                                            git add metadata.json
                                                                                                            if [[ -d "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                            then
                                                                                                                :
                                                                                                            elif [[ -f "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                            then
                                                                                                                mkdir parts
                                                                                                                cd parts
                                                                                                                split --bytes=1M "$ABSOLUTE_FILE"
                                                                                                                git add .
                                                                                                            else
                                                                                                                failure 9280299813662959
                                                                                                            fi
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
                                                                                        GRADLE_USER_HOME="$( mktemp --directory )" || failure 6182679945594691
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
                                                                                        find gradle-dependencies -mindepth 1 -exec explode {} \;
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