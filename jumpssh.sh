ROYAL_DEBUG_ME=0
ROYAL_LAST_IS_SWITCH=1
ROYAL_LAST_IS_EMPTY=1
ROYAL_DO_NOT_CONNECT=0
ROYAL_LAST_COMMAND="echo "
export ROYAL_FILETARGET=~/lab/scripts/contents/all.txt
export ROYAL_LAST_SEARCH_FILE=~/lab/scripts/contents/searchstring.txt

function resetroyalsettings() {
    ROYAL_DEBUG_ME=0
    ROYAL_LAST_IS_SWITCH=1
    ROYAL_LAST_IS_EMPTY=1
    ROYAL_DO_NOT_CONNECT=0
}

function debugme() {
    if [ "$ROYAL_DEBUG_ME" -eq "1" ]; then
        echo ">> DEBUG: $1"
    fi
}

function assh() {
    cop $2
    S_HOST=$1
    shift
    shift
    sshpass -e ssh -o StrictHostKeyChecking=no $S_HOST "$@"
}

function isEmpty() {
    ROYAL_LAST_IS_EMPTY=1
    if [[ "$1" = "" ]] ;
    then
        debugme "is empty"
        ROYAL_LAST_IS_EMPTY=0
    fi
    debugme "is not empty"
}

function isSwitch() {
    ROYAL_LAST_IS_SWITCH=1
    if [[ $1 = -* ]] ;
    then
        debugme "is switch"
        ROYAL_LAST_IS_SWITCH=0
    fi
    debugme "is not switch"
}

function jshc() {
    echo "jsh $ROYAL_LAST_COMMAND -c"
}

function mjsh(){
    jsh $(tuijsh)
    #  has_value=`tjsh`
    #  if [ -z "$has_value" ]
    #  then
    #    echo "empty"
    #  else
    #    echo "not empty jsh $has_value"
    #    #jsh ${has_value}
    #    jsh
    #    jsh `$has_value`
    #  fi
}

function jsh() {
    resetroyalsettings
    S_FILETARGET=~/lab/scripts/contents/all.txt
    S_FILEPRODTARGET=~/lab/scripts/contents/prodall.txt

    if [[ $# -eq 0 ]] ; then
        echo 'No arguments'
        return 0
    fi

    S_SEARCH=$1
    shift

    # Give listing
    if [ $S_SEARCH = '-l' ]; then
        cat $S_FILETARGET
        return
    fi
    if [ $S_SEARCH = '-lp' ]; then
        cat $S_FILEPRODTARGET
        return
    fi

    S_PASSWORD=''
    S_CONNECT='false'
    S_PING='false'
    S_USER=''
    S_MANUAL='false'
    S_NOTINCLUDE=""
    S_EXECUTE_COMMAND=""
    S_MYSQL_COMMAND='false'
    S_ORACLE_COMMAND='false'
    S_MYSQL_LOGIN='false'
    S_SERVICE_ENABLED=0
    S_SERVICE='web'
    S_SERVICE_TYPE='status'
    S_SERVICE_PATH_PRE='/et/services'
    S_SERVICE_PATH_POST='bin/service.sh'
    S_COPY_OUTPUT_COMMAND='false'
    S_DOC=0

    if [[ "'$*'" = *-d* ]] ;
    then
        ROYAL_DEBUG_ME=1
        echo "================ SET DEBUG"
    fi

    while [[ $# -gt 0 ]]
    do
        KEY="$1"
        case $KEY in
            '-f' ) # fake connect
                ROYAL_DO_NOT_CONNECT=1
                shift
                ;;
            '-s' ) # debug skip it
                shift
                ;;
            '-c' ) # too lazy to type 
                S_CONNECT='true'
                S_USER="etadm"
                S_PASSWORD="p"
                shift
                ;;
            '-et' ) # service
                S_SERVICE_ENABLED=1
                S_SERVICE="$2"
                shift
                shift
                S_SERVICE_TYPE="$1"
                shift
                ;;
            '-o' )
                S_COPY_OUTPUT_COMMAND='true'
                shift
                ;;
            '-p' ) # grab password
                debugme "password"
                S_CONNECT='true'
                S_PASSWORD="$2"
                isSwitch $2
                isEmpty $2
                shift
                if [ "$ROYAL_LAST_IS_SWITCH" -eq "0" ]; 
                then
                    S_PASSWORD="p"
                elif [ "$ROYAL_LAST_IS_EMPTY" -eq "0" ];
                then
                    S_PASSWORD="p"
                else
                    shift
                fi
                ;;
            '-j' ) # path zk
                export copy_path=""
                case $2 in
                    'local' )
                        export copy_path="/et/local/services"
                        ;;
                    'clogs' )
                        export copy_path="/et/local/services/cas/logs/cassandra"
                        ;;
                    'zlogs' )
                        export copy_path="/et/local/services/zkp/logs"
                        ;;
                    'cas' )
                        export copy_path="/et/software/cas"
                        ;;
                    'zstatus' )
                        export copy_path="/et/software/zkp/bin/zkServer.sh status"
                        ;;
                    'install' )
                        export copy_path="/et/install"
                        ;;
                    'zk' )
                        export copy_path="/et/software/zkp/bin/zkCli.sh"
                        ;;
                    * )
                        ;;
                esac
                if [ "$copy_path" = "" ]; then
                    echo "no path"
                else
                    echo -n "$copy_path" | pbcopy
                fi
                shift
                shift
                ;;
            '-doc' ) # docker states
                S_DOC=1
                shift
                ;;
            '-u' ) # user
                S_USER="$2"
                isSwitch $2
                isEmpty $2
                debugme "last command results is $ROYAL_LAST_IS_SWITCH"
                shift
                # is a switch then just assign the value
                if [ "$ROYAL_LAST_IS_SWITCH" -eq "0" ]; 
                then
                    debugme "is a switch assign etadm"
                    S_USER="etadm"
                elif [ "$ROYAL_LAST_IS_EMPTY" -eq "0" ];
                then
                    debugme "empty assign etadm"
                    S_USER="etadm"
                else
                    shift
                fi
                debugme "user is $S_USER"
                ;;
            '-t' ) # ping it
                S_PING='true'
                shift
                ;;
            '-m' ) # manually connect with the string
                S_MANUAL='true'
                shift
                ;;
            '-a' ) # add on to the search term
                S_SEARCH="$S_SEARCH.*$2"
                debugme $S_SEARCH
                shift
                shift
                ;;
            '-v' ) # does not include
                S_NOTINCLUDE="$2"
                debugme "exclude $S_NOTINCLUDE"
                shift
                shift
                ;;
            '-exec' ) # record and quit
                S_EXECUTE_COMMAND="$2"
                shift
                shift
                ;;
            '-qq' )
                S_MYSQL_COMMAND='true'
                S_MYSQL_LOGIN="$2"
                shift
                shift
                ;;
            '-q' )
                S_MYSQL_COMMAND='true'
                shift
                ;;
            '-P' ) # use production list
                S_FILETARGET=$S_FILEPRODTARGET
                shift
                ;;
            * )
                debugme "add to search $1"
                S_SEARCH="$S_SEARCH.*$1"
                shift
                ;;
        esac
    done

    # manual seach
    if [ "$S_SEARCH" ] || [ $S_MANUAL = 'true' ] || [ $S_COPY_OUTPUT_COMMAND = 'true' ]; then

        # copy the output
        if [ $S_COPY_OUTPUT_COMMAND = 'true' ]; then
            S_COPY=$(grep -i $S_SEARCH $S_FILETARGET)
            echo "$S_COPY" | pbcopy
        fi

        # if true don't interpret anything just run the command
        if [ $S_MANUAL = 'true' ]; then
            S_CURRENTURI=$S_SEARCH
            # list jump points
        else
            S_CURRENTURI=$(grep -i $S_SEARCH $S_FILETARGET | grep -o "=.*" | cut -c2- | head -n 1)

            # not include in connection run command with inverse
            if [ "$S_NOTINCLUDE" != "" ]; then
                debugme "not include is $S_NOTINCLUDE"
                echo "not include" 
                S_CURRENTURI=$(grep -i $S_SEARCH $S_FILETARGET | grep -o "=.*" | grep -iv $S_NOTINCLUDE | cut -c2- | head -n 1)
            fi
        fi
    
        # start ping
        if [ "$S_PING" = 'true' ]; then
            debugme "ping this $S_CURRENTURI"
            ping $S_CURRENTURI  
            # connect regularly
        elif [ "$S_CONNECT" = 'true' ]; then
            debugme "connect string $S_SEARCH"
            debugme "string should be $S_CURRENTURI";
            if [ "$S_USER" != "" ]; then
                S_USER="$S_USER@"
            fi
            if [ "$S_PASSWORD" ]; then
                echo "login: $S_USER$S_CURRENTURI $S_PASSWORD" #'$S_EXECUTE_COMMAND'"
                if [ $ROYAL_DO_NOT_CONNECT -eq "0" ] ; 
                then
                    # restart service 
                    if [ $S_SERVICE_ENABLED -eq "1" ] ; 
                    then
                        echo "assh service"
                        assh $S_USER$S_CURRENTURI $S_PASSWORD "$S_SERVICE_PATH_PRE/$S_SERVICE/$S_SERVICE_PATH_POST $S_SERVICE_TYPE"
                        # execute with query
                    elif [ "$S_DOC" -eq "1" ]
                    then
                        echo "assh docker"
                        assh $S_USER$S_CURRENTURI $S_PASSWORD "docker ps"
                    elif [ "$S_EXECUTE_COMMAND" != "" ]
                    then
                        echo "assh execute"
                        assh $S_USER$S_CURRENTURI $S_PASSWORD "$S_EXECUTE_COMMAND"
                    else
                        echo "assh "
                        assh $S_USER$S_CURRENTURI $S_PASSWORD #'$S_EXECUTE_COMMAND'
                    fi
                fi
            else
                echo "ssh $S_USER$S_CURRENTURI"
                if [ $ROYAL_DO_NOT_CONNECT -eq "0" ] ; 
                then
                    if [ $S_SERVICE_ENABLED -eq "1" ] ; 
                    then
                        echo "ssh services"
                        ssh $S_USER$S_CURRENTURI "$S_SERVICE_PATH_PRE/$S_SERVICE/$S_SERVICE_PATH_POST $S_SERVICE_TYPE"
                    elif [ "$S_DOC" -eq "1" ]
                    then
                        echo "ssh stats"
                        ssh $S_USER$S_CURRENTURI "docker ps"
                    elif [ "$S_EXECUTE_COMMAND" != "" ]
                    then
                        echo "ssh execute"
                        ssh $S_USER$S_CURRENTURI "$S_EXECUTE_COMMAND"
                    else
                        echo "ssh"
                        ssh $S_USER$S_CURRENTURI #'$S_EXECUTE_COMMAND'
                    fi
                fi
            fi
        elif [ "$S_MYSQL_COMMAND" = 'true' ]; then
            if [ "$S_MYSQL_LOGIN" = 'false' ]; then
                /usr/local/bin/mysql -h $S_CURRENTURI -u etadm -e "show databases;"
            else
                /usr/local/bin/mysql -h $S_CURRENTURI -u etadm $S_MYSQL_LOGIN
            fi
        else
            # if it has something to exclude run the exclusion
            if [ "$S_NOTINCLUDE" != "" ]; then
                grep -i "$S_SEARCH" $S_FILETARGET | grep -iv $S_NOTINCLUDE
            else
                grep -i "$S_SEARCH" $S_FILETARGET
            fi
        fi
    else
        cat $S_FILETARGET
    fi
}
