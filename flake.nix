{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    { } :
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
                                                        build =
                                                            lib.mkOption
                                                                {
                                                                    default =
                                                                        pkgs.writeShellApplication
                                                                            {
                                                                                name = "build" ;
                                                                                runtimeInputs =
                                                                                    [
                                                                                        pkgs.coreutils
                                                                                        pkgs.findutils
                                                                                        (
                                                                                            pkgs.writeShellApplication
                                                                                                {
                                                                                                    name = "implode" ;
                                                                                                    runtimeInputs =
                                                                                                        [
                                                                                                            pkgs.jq
                                                                                                            ( config.failure { } )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            RELATIVE_INPUT_FILE="$1"
                                                                                                            PERMISSIONS="$( jq --raw-output ".permissions" "$RELATIVE_INPUT_FILE/manifest.json" )" || failure 9329627089274214
                                                                                                            TAG="$( jq --raw-output ".tag" "$RELATIVE_INPUT_FILE/manifest.json" )" || failure 3951886682959815
                                                                                                            TYPE="$( jq --raw-output ".type" "$RELATIVE_INPUT_FILE/manifest.json" )" || failure 9577007111979114
                                                                                                            RELATIVE_OUTPUT_FILE="$RESOURCE/grade-dependencies/$TAG"
                                                                                                            RELATIVE_OUTPUT_DIRECTORY="$( dirname "$RELATIVE_OUTPUTFILE" )" || failure 6433247134074053
                                                                                                            mkdir --parents "$RELATIVE_OUTPUT_DIRECTORY"
                                                                                                            if [[ "$TYPE" == "directory" ]]
                                                                                                            then
                                                                                                                mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                            elif [[ "$TYPE" == "regular file" ]]
                                                                                                            then
                                                                                                                cat "$RELATIVE_INPUT_FILE/parts/*" > "$RELATIVE_OUTPUT_FILE"
                                                                                                            else
                                                                                                                failure 6788572980989981 "$RELATIVE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                            fi
                                                                                                            chmod "$PERMISSIONS" "$REGULAR_OUTPUT_FILE
                                                                                                        '' ;
                                                                                                }
                                                                                        )
                                                                                        ( config.failure { } )
                                                                                    ] ;
                                                                                text =
                                                                                    ''
                                                                                        RESOURCE="$( mktemp --directory )" || failure 1131106762433829
                                                                                        export RESOURCE
                                                                                        cp --recursive ${ ./. }/. "$RESOURCE"
                                                                                        chmod -R a+rwx "$RESOURCE"
                                                                                        find "$RESOURCE/gradle-dependencies.exploded" -mindepth 1 -maxdepth 1 -exec implode {} \;
                                                                                        export ANDROID_HOME="${ androidSdk }"
                                                                                        WORK_DIR="$(mktemp --directory)" || failure 3113983533329552
                                                                                        echo "WORK_DIR=$WORK_DIR"
                                                                                        cd "$WORK_DIR"
                                                                                        cp --recursive "$RESOURCE/frontend/mobile/." .
                                                                                        chmod --recursive u+rwX "$WORK_DIR"
                                                                                        find "$WORK_DIR" -type d -name "*.jar.exploded" -exec implode {} \;
                                                                                        export HOME="$WORK_DIR/home"
                                                                                        export GRADLE_USER_HOME="$HOME/.gradle"
                                                                                        mkdir --parents "$GRADLE_USER_HOME"
                                                                                        cp --recursive "$WORK_DIR/gradle-dependencies/." "$GRADLE_USER_HOME/caches/"
                                                                                        chmod --recursive u+rwX "$WORK_DIR"
                                                                                        gradle \
                                                                                            -Pandroid.aapt2FromMavenOverride="$ANDROID_HOME/libexec/android-sdk/build-tools/35.0.0/aapt2" \
                                                                                            build \
                                                                                            --offline
                                                                                        mkdir --parents "$out"
                                                                                        cp --recursive app/build/outputs/. "$out"/
                                                                                        rm --recursive --force "$RESOURCE" "$WORK_DIR"
                                                                                    '' ;
                                                                            } ;
                                                                    type = lib.types.functionTo lib.types.package ;
                                                                } ;
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
                                                                                        ( config.failure { } )
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
                                                                                                            ( config.failure { } )
                                                                                                        ] ;
                                                                                                    text =
                                                                                                        ''
                                                                                                            RELATIVE_INPUT_FILE="$1"
                                                                                                            ABSOLUTE_INPUT_FILE="$( realpath "$RELATIVE_INPUT_FILE" )" || failure 7667864193624809
                                                                                                            HASH="$( echo "$RELATIVE_FILE" | sha512sum | cut --characters 1-128 )" || failure 4885129150129948
                                                                                                            mkdir --parents "gradle-dependencies.exploded/$HASH"
                                                                                                            cd "gradle-dependencies.exploded/$HASH"
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