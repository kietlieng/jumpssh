ROYAL_DEBUG_ME=0
ROYAL_LAST_IS_SWITCH=1
ROYAL_LAST_IS_EMPTY=1
ROYAL_DO_NOT_CONNECT=0
ROYAL_LAST_COMMAND="echo "

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

function jsh() {
  resetroyalsettings
  S_FILETARGET=~/lab/scripts/contents/all.txt
  S_SEARCH=$1
  shift

  # Give listing
  if [ $S_SEARCH = '-l' ]; then
    cat $S_FILETARGET
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
    '-d' ) # debug skip it
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
    * )
      debugme "add to search $1"
      S_SEARCH="$S_SEARCH.*$1"
      shift
      ;;
       esac
    done

    if [ "$S_SEARCH" ] || [ $S_MANUAL = 'true' ]; then
       if [ $S_MANUAL = 'true' ]; then
        S_CURRENTURI=$S_SEARCH
      else
        S_CURRENTURI=$(grep -i $S_SEARCH $S_FILETARGET | grep -o "=.*" | cut -c2- | head -n 1)

        # not include in connection
         if [ "$S_NOTINCLUDE" != "" ]; then
          debugme "not include is $S_NOTINCLUDE"
          S_CURRENTURI=$(grep -i $S_SEARCH $S_FILETARGET | grep -o "=.*" | grep -iv $S_NOTINCLUDE | cut -c2- | head -n 1)
      fi
     fi
    if [ "$S_PING" = 'true' ]; then
      debugme "ping this $S_CURRENTURI"
      ping $S_CURRENTURI  
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
