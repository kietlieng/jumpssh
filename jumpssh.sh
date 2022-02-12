royal_debug_me=0
royal_last_is_switch=1
royal_last_is_empty=1
royal_do_not_connect=0
royal_list_command="echo "

export royal_filetarget=~/lab/scripts/servers/all.txt
export royal_file_prod_target=~/lab/scripts/servers/prodall.txt
export royal_last_search_file=~/lab/scripts/servers/searchstring.txt

function resetroyalsettings() {
    royal_debug_me=0
    royal_last_is_switch=1
    royal_last_is_empty=1
    royal_do_not_connect=0
}

function debugme() {
    if [ "$royal_debug_me" -eq "1" ]; then
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
    royal_last_is_empty=1
    if [[ "$1" = "" ]] ;
    then
        debugme "is empty"
        royal_last_is_empty=0
    fi
    debugme "is not empty"
}

function isSwitch() {
    royal_last_is_switch=1
    if [[ $1 = -* ]] ;
    then
        debugme "is switch"
        royal_last_is_switch=0
    fi
    debugme "is not switch"
}

function jshc() {
    echo "jsh $royal_list_command -c"
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
    sFileTarget="$royal_filetarget"
    sFileProdTarget="$royal_file_prod_target"

    if [[ $# -eq 0 ]] ; then
        echo 'No arguments'
        return 0
    fi

    # we don't want the search string.
    # variable will be useful only for tmux
    sSearch=$1
    shift
    #sAllArgs="${@}"
    sAllArgs=""

    # Give listing
    if [ $sSearch = '-l' ]; then
        cat $sFileTarget
        return
    fi
    if [ $sSearch = '-lp' ]; then
        cat $sFileProdTarget
        return
    fi

    sConnect='false'
    sCopyOutputCommand='false'
    sDoc=0
    sExecuteCommand=""
    sList='false'
    sManual='false'
    sMysqlCommand='false'
    sMysqlLogin='false'
    sNotInclude=""
    sOracleCommand='false'
    sPassword=''
    sPing='false'
    sPrettyPrint='false'
    sService='web'
    sServiceEnabled=0
    sServicePathPost='bin/service.sh'
    sServicePathPre='/et/services'
    sServiceType='status'
    sUser=''
    sTmux=''

    if [[ "'$*'" = *-d* ]] ;
    then
        royal_debug_me=1
        echo "================ SET DEBUG"
    fi

    lastArg1=""
    lastArg2=""
    while [[ $# -gt 0 ]]
    do
        key="$1"
        #echo "key $1"
        #echo "starting $sAllArgs"
        # if listArg1 has value
        if [[ "" != "$lastArg1" ]]; then
            #echo "concat $lastArg1 $lastArg2 to $sAllArgs"
            sAllArgs="${sAllArgs}${lastArg1}${lastArg2}"
        fi

        lastArg1=" $1"
        lastArg2=""

        case $key in
            '-f' ) # fake connect
                royal_do_not_connect=1
                shift
                ;;
            '-s' ) # debug skip it
                shift
                ;;
            '-c' ) # too lazy to type 
                sConnect='true'
                # if this hasn't been set already
                if [[ "" == "$sUser" ]]; then
                    sUser="etadm"
                fi
                # if this hasn't been set already
                if [[ "" == "$sPassword" ]]; then
                    sPassword="p"
                fi
                shift
                ;;
            '-list' ) # service
                sList='true'
                shift
                ;;
            '-et' ) # service
                # copy this command options to connect
                # if this hasn't been set already
                sConnect='true'
                if [[ "" == "$sUser" ]]; then
                    sUser="etadm"
                fi
                # if this hasn't been set already
                if [[ "" == "$sPassword" ]]; then
                    sPassword="p"
                fi
                
                # regular command
                sServiceEnabled=1
                sService="$2"
                lastArg2=" $2"
                shift
                shift
                # grab service type
                sServiceType="$1"
                shift
                ;;
            '-tm' )
                sTmux='true'
                #sAllArgs="${sAllArgs/ -tm/}"
                lastArg1=""
                lastArg2=""

                shift
                ;;
            '-o' )
                sCopyOutputCommand='true'
                shift
                ;;
            '-pretty' )
                sPrettyPrint='true'
                shift
                ;;
            '-p' ) # grab password
                debugme "password"
                sConnect='true'
                sPassword="$2"
                isSwitch $2
                isEmpty $2
                shift
                if [ "$royal_last_is_switch" -eq "0" ]; 
                then
                    sPassword="p"
                    lastArg2=" p"
                elif [ "$royal_last_is_empty" -eq "0" ];
                then
                    sPassword="p"
                    lastArg2=" p"
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
                    'lc' )
                        export copy_path="/et/local/services/cas/logs/cassandra"
                        ;;
                    'lz' )
                        export copy_path="/et/local/services/zkp/logs"
                        ;;
                    'sc' )
                        export copy_path="/et/software/cas"
                        ;;
                    'zkstat' )
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
                lastArg2= "$copy_path"
                shift
                shift
                ;;
            '-doc' ) # docker states
                sDoc=1
                shift
                ;;
            '-u' ) # user
                sUser="$2"
                sConnect='true'
                isSwitch $2
                isEmpty $2
                debugme "last command results is $royal_last_is_switch"
                shift
                # is a switch then just assign the value
                if [ "$royal_last_is_switch" -eq "0" ]; 
                then
                    debugme "is a switch assign etadm"
                    sUser="etadm"
                elif [ "$royal_last_is_empty" -eq "0" ];
                then
                    debugme "empty assign etadm"
                    sUser="etadm"
                else
                    shift
                fi
                lastArg2=" $sUser"
                case $sUser in
                    'root' ) 
                        echo "root user password"
                        sPassword="e"
                        ;;
                    'oracle' )
                        echo "oracle password"
                        sPassword="o"
                        ;;
                    * )
                        sPassword="p"
                        echo "no password assumed"
                        ;;
                esac

                debugme "user is $sUser"
                ;;
            '-t' ) # ping it
                sPing='true'
                shift
                ;;
            '-m' ) # manually connect with the string
                sManual='true'
                shift
                ;;
            '-a' ) # add on to the search term
                sSearch="$sSearch.*$2"
                debugme $sSearch
                shift
                shift
                ;;
            '-v' ) # does not include
                sNotInclude="$2"
                debugme "exclude $sNotInclude"
                shift
                shift
                ;;
            '-exec' ) # record and quit
                sExecuteCommand="$2"
                lastArg2=" $2"
                shift
                shift
                ;;
            '-qq' )
                sMysqlCommand='true'
                sMysqlLogin="$2"
                lastArg2=" $2"
                shift
                shift
                ;;
            '-q' )
                sMysqlCommand='true'
                shift
                ;;
            '-P' ) # use production list
                sFileTarget=$sFileProdTarget
                shift
                ;;
            * )
                debugme "add to search $1"
                lastArg1=""
                lastArg2=""
                # remove the search string
                #sAllArgs=${sAllArgs/$1/}
                sSearch="$sSearch.*$1"
                shift
                ;;
        esac
    done
    #echo "lastarg1 |$lastArg1| $sAllArgs"
    # if listArg1 has value
    if [[ "" != "$lastArg1" ]]; then
    #    echo "last add"
        sAllArgs="${sAllArgs}${lastArg1}${lastArg2}"
    fi
    #echo "allargs | ${sAllArgs} |"
    #return
    # manual seach
    if [ "$sSearch" ] || [ $sManual = 'true' ] || [ $sCopyOutputCommand = 'true' ]; then

        # copy the output
        if [ $sCopyOutputCommand = 'true' ]; then
            S_COPY=$(grep -i $sSearch $sFileTarget)
            echo "$S_COPY" | pbcopy
        fi

        # if true don't interpret anything just run the command
        if [ $sManual = 'true' ]; then
            sCurrentURI=$sSearch
            # list jump points
        else
            if [[ "$sTmux" == "true" ]]; then
                sCurrentURI=$(grep -i $sSearch $sFileTarget | grep -o "=.*" | cut -c2-)
            else
                sCurrentURI=$(grep -i $sSearch $sFileTarget | grep -o "=.*" | cut -c2- | head -n 1)
            fi

            # not include in connection run command with inverse
            if [ "$sNotInclude" != "" ]; then
                debugme "not include is $sNotInclude"
                echo "not include" 
                if [[ "$sTmux" == "true" ]]; then
                    sCurrentURI=$(grep -i $sSearch $sFileTarget | grep -o "=.*" | grep -iv $sNotInclude | cut -c2- )
                else
                    sCurrentURI=$(grep -i $sSearch $sFileTarget | grep -o "=.*" | grep -iv $sNotInclude | cut -c2- | head -n 1)
                fi
            fi
        fi
        #echo "counter $counter |$sCurrentURI|"
        # split on 
        #echo "tmux value $sTmux"
        # if tmux option is true create the panes by passing the ip of the currentIP variable to jsh. 
        # basically using jsh to create tmux sessions that will in affect call jsh 
        if [[ "$sTmux" == "true" ]]; then
            tmuxCommand=""
            paneName="tpane"
            firstPane="t"

            # iterate through listing
            for currentIP in $(sed 's/:/\n/g' <<< $sCurrentURI)
            do
                if [[ "$firstPane" == "t" ]]; then
                    tmux new-session -d -s $paneName
                    firstPane="f"
                else
                    tmux split-window -h -t $paneName
                fi

                # get the specific entry by recreating sCurrentURI keyed to IP
                tmCurrentURI=$(grep -i $sSearch $sFileTarget | grep "$currentIP")

                # generate the output properly
                echo "jsh $tmCurrentURI $sAllArgs" 
                
                # send command to the output properly
                tmux send-keys -t $paneName "jsh $tmCurrentURI $sAllArgs" Enter

                # have to readjust pane space after you add a new pane
                # (the panes are divided in half between on the current pane so 
                # you will eventually get smaller and smaller panes for the next 
                # session.  Will run out of pane space after about 7 panes
                # more will not be created
                tmux select-layout -t $paneName even-horizontal

                echo "\"jsh $tmCurrentURI $currentIP\" "
#                tmuxCommand="$tmuxCommand \"jsh $tmCurrentURI $currentIP\" "
            done

            # firstPane to false means there was at least 1 tmux session. 
            if [[ "$firstPane" == "f" ]]; then
                
                # I want to select the left most pane so just go right to warp
                # to the left most pane
                tmux select-pane -t $paneName -R

                tmux select-layout -t $paneName tiled
                tmux set-window-option -t $paneName synchronize-panes on
                tmux attach -t $paneName
            fi

            # done don't process any other conditionals
            return
        fi
    
        # start ping
        if [ "$sPing" = 'true' ]; then
            debugme "ping this $sCurrentURI"
            ping $sCurrentURI  
            # connect regularly
        elif [ "$sConnect" = 'true' ]; then
            debugme "connect string $sSearch"
            debugme "string should be $sCurrentURI";
            if [ "$sUser" != "" ]; then
                sUser="$sUser@"
            fi
            if [ "$sPassword" ]; then
                echo "login: $sUser$sCurrentURI $sPassword" #'$sExecuteCommand'"
                if [ $royal_do_not_connect -eq "0" ] ; 
                then
                    # restart service 
                    if [ $sServiceEnabled -eq "1" ] ; 
                    then
                        echo "assh service"
                        assh $sUser$sCurrentURI $sPassword "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
                    # execute with query
                    elif [ "$sList" = "true" ]; 
                    then
                        echo "assh list services"
                        assh $sUser$sCurrentURI $sPassword "ls $sServicePathPre"
                    elif [ "$sDoc" -eq "1" ]
                    then
                        echo "assh docker"
                        assh $sUser$sCurrentURI $sPassword "docker ps"
                    elif [ "$sExecuteCommand" != "" ]
                    then
                        echo "assh execute"
                        assh $sUser$sCurrentURI $sPassword "$sExecuteCommand"
                   else
                        echo "assh "
                        assh $sUser$sCurrentURI $sPassword #'$sExecuteCommand'
                    fi
                fi
            else
                echo "ssh $sUser$sCurrentURI"
                if [ $royal_do_not_connect -eq "0" ] ; 
                then
                    if [ $sServiceEnabled -eq "1" ] ; 
                    then
                        echo "ssh services"
                        ssh $sUser$sCurrentURI "$sServicePathPre/$sService/$sServicePathPost $sServiceType"
                    elif [ "$sDoc" -eq "1" ]
                    then
                        echo "ssh stats"
                        ssh $sUser$sCurrentURI "docker ps"
                    elif [ "$sExecuteCommand" != "" ]
                    then
                        echo "ssh execute"
                        ssh $sUser$sCurrentURI "$sExecuteCommand"
                    else
                        echo "ssh"
                        ssh $sUser$sCurrentURI #'$sExecuteCommand'
                    fi
                fi
            fi
        elif [ "$sMysqlCommand" = 'true' ]; then
            if [ "$sMysqlLogin" = 'false' ]; then
                /usr/local/bin/mysql -h $sCurrentURI -u etadm -e "show databases;"
            else
                /usr/local/bin/mysql -h $sCurrentURI -u etadm $sMysqlLogin
            fi
        else
            # if it has something to exclude run the exclusion
            if [ "$sNotInclude" != "" ]; then
                grep -i "$sSearch" $sFileTarget | grep -iv $sNotInclude
            else

                if [ "$sPrettyPrint" = 'true' ]; then
                  grep -i "$sSearch" $sFileTarget | sed 's/\^.*=/=/g'
                else
                  grep -i "$sSearch" $sFileTarget 
                fi
    
            fi
        fi
    else
        cat $sFileTarget
    fi
}
