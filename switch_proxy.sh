#!/bin/bash
#if (($EUID != 0)); then
#	if [ -t 1 ]; then
#		sudo "$0" "$@"
#		exit 0
#	else
#		gksudo "$0" "$@"
#		exit 0
#	fi
#fi

SUDOPAS=`zenity --password --text="Inserisci la password di sudo" --title="Password richiesta"`
if [[ $SUDOPAS == "" ]];then
	echo "devi specificare la password di sudo"
	exit 1
fi

#if `echo $SUDOPAS | sudo -S -- grep -i "http_proxy" /etc/sudoers`;then
#	echo "Devi aggiungere questa riga al tuo visudo perchè il proxy funzioni in maniera ottimale"
#	echo
#	echo 'Defaults env_keep +="http_proxy HTTP_PROXY https_proxy HTTPS_PROXY ftp_proxy FTP_PROXY socks_proxy SOCKS_PROXY no_proxy NO_PROXY"'
#	echo
#	echo "Quando lo avrai fatto rilanciami"
#	exit 1
#fi

SCELTA=`ls -A -B ./config/ | zenity --list --title="Selezione Proxy" --text="Scegli le impostazioni che preferisci" --hide-header --column="scelta"`

if [[ $SCELTA == "Aggiungi_nuovo_Proxy" ]];then
	SERVERS=`zenity --forms --title="Aggiungi un nuovo Proxy" --text="Inserisci i dati, lascia vuoto per non usare un tipo di proxy" --add-entry="Nome:" --add-entry="HTTP PROXY" --add-entry="HTTP PORTA" --add-entry="HTTPS PROXY" --add-entry="HTTPS PORTA" --add-entry="FTP PROXY" --add-entry="FTP PORTA" --add-entry="SOCKS PROXY" --add-entry="SOCKS PORTA"`
	ARPR=(${SERVERS//\|/ })
	touch "./config/${ARPR[0]}"
	echo "#!/bin/bash" > "./config/${ARPR[0]}"
	echo "http_host=\"${ARPR[1]}\"" >> "./config/${ARPR[0]}"
	echo "http_port=\"${ARPR[2]}\"" >> "./config/${ARPR[0]}"
	echo "https_host=\"${ARPR[3]}\"" >> "./config/${ARPR[0]}"
	echo "https_port=\"${ARPR[4]}\"" >> "./config/${ARPR[0]}"
	echo "ftp_host=\"${ARPR[5]}\"" >> "./config/${ARPR[0]}"
	echo "ftp_port=\"${ARPR[6]}\"" >> "./config/${ARPR[0]}"
	echo "socks_host=\"${ARPR[7]}\"" >> "./config/${ARPR[0]}"
	echo "socks_port=\"${ARPR[8]}\"" >> "./config/${ARPR[0]}"
	zenity --question --title="Autenticazione proxy" --text="Il tuo proxy richiede nome utente e password?"
	if [[ $? == 0 ]] ; then
		echo "http_use_authentication=\"true\"" >> "./config/${ARPR[0]}"
		AUTHDATA=`zenity --forms --title="Autenticazione proxy" --text="Inserisci nome utente e password se vuoi salvarli, lascia bianco se vuoi inserirli ogni volta" --add-entry="Nome utente:"  --add-password="Password:"`
		ARAT=(${AUTHDATA//\|/ })
		echo "http_auth_user=\"${ARAT[0]}\"" >> "./config/${ARPR[0]}"
		echo "http_auth_password=\"${ARAT[1]}\"" >> "./config/${ARPR[0]}"
	else
		echo "http_use_authentication=\"false\"" >> "./config/${ARPR[0]}"
	fi
	IGNORE=`zenity --entry --title="Ignore-host" --text="Inserisci gli indirizzi host da ignorare (lascia com'è se non sei sicuro)" --entry-text="localhost,127.0.0.0/8,192.0.0.0/8"`
	echo "no_proxy=\"$IGNORE\"" >> "./config/${ARPR[0]}"
	DESCR=`zenity --entry --title "Descrizione" --text="Se vuoi puoi inserire una descrizione nel file:"`
	echo "#Descrizione: $DESCR" >> "./config/${ARPR[0]}"
	SCELTA=${ARPR[0]}
elif [[ $SCELTA != "" ]]; then
	source "./config/$SCELTA"
#		if [[ $http_use_authentication && !$http_auth_user ]];then
#			authproxy=`zenity --forms --title="Autenticazione richiesta Proxy Direzione Liguria" --text="Il proxy richiede un nome utente e una password" --add-entry="Nome utente:"  --add-password="Password:"`
#			ARAU=(${authproxy//\|/ })
#			http_auth_user=${ARAU[0]}
#			http_auth_password=${ARAU[1]}
#			saveauth=`zenity --question --title="Vuoi salvare i dati?" --text="Vuoi salvare i dati? (verranno salvati non criptati!)"`
#			if [[ $saveauth ]];then
#				echo "http_auth_user=\"$http_auth_user\"" >> "./config/$SCELTA"
#				echo "http_auth_password=\"$http_auth_password\"" >> "./config/$SCELTA"
#			fi
#		fi

	if [[ $http_host != "" ]]; then
		gsettings set org.gnome.system.proxy.http enabled true
		gsettings set org.gnome.system.proxy mode manual
	else
		gsettings set org.gnome.system.proxy.http enabled false
		gsettings set org.gnome.system.proxy mode none
		http_port="0";
		https_port="0";
		ftp_port="0";
		socks_port="0";
	fi
	gsettings set org.gnome.system.proxy ignore-hosts "$ignore_hosts"
	gsettings set org.gnome.system.proxy use-same-proxy false
	gsettings set org.gnome.system.proxy.http host "$http_host"
	gsettings set org.gnome.system.proxy.http port "$http_port"
	gsettings set org.gnome.system.proxy.http use-authentication "$http_use_authentication"
	gsettings set org.gnome.system.proxy.http authentication-user "$http_auth_user"
	gsettings set org.gnome.system.proxy.http authentication-password "$http_auth_password"
	gsettings set org.gnome.system.proxy.https host "$https_host"
	gsettings set org.gnome.system.proxy.https port "$https_port"
	gsettings set org.gnome.system.proxy.ftp host "$ftp_host"
	gsettings set org.gnome.system.proxy.ftp port "$ftp_port"
	gsettings set org.gnome.system.proxy.socks host "$socks_host"
	gsettings set org.gnome.system.proxy.socks port "$socks_port"
	#if apt is in use
	if [[ -d "/etc/apt/apt.conf.d" ]]; then
		echo $SUDOPAS | sudo -S -- rm /etc/apt/apt.conf.d/02proxy
		echo $SUDOPAS | sudo -S -- touch /etc/apt/apt.conf.d/02proxy
		echo $SUDOPAS | sudo -S -- chown $USER /etc/apt/apt.conf.d/02proxy
		if [[ $http_host != "" ]]; then
			echo "Acquire::http::Proxy \"http://${http_auth_user}:${http_auth_password}@${http_host}:${http_port}/\";" >> /etc/apt/apt.conf.d/02proxy
		fi
		if [[ $https_host != "" ]]; then
			echo "Acquire::https::Proxy \"https://${http_auth_user}:${http_auth_password}@${https_host}:${https_port}/\";" >> /etc/apt/apt.conf.d/02proxy
		fi
		if [[ $ftp_host != "" ]]; then
			echo "Acquire::ftp::Proxy \"ftp://${http_auth_user}:${http_auth_password}@${ftp_host}:${ftp_port}/\";" >> /etc/apt/apt.conf.d/02proxy
		fi
		if [[ $socks_host != "" ]]; then
			echo "Acquire::socks::Proxy \"socks://${http_auth_user}:${http_auth_password}@${socks_host}:${socks_port}/\";" >> /etc/apt/apt.conf.d/02proxy
		fi
	fi
	if [[ $http_host != "" ]]; then
		export HTTP_PROXY="http://${http_auth_user}:${http_auth_password}@${http_host}:${http_port}/"
		export http_proxy=$HTTP_PROXY
	else
		export HTTP_PROXY=""
		export http_proxy=$HTTP_PROXY
	fi
	if [[ $ftp_host != "" ]]; then
		export FTP_PROXY="ftp://${http_auth_user}:${http_auth_password}@${ftp_host}:${ftp_port}/"
		export ftp_proxy=$FTP_PROXY
	else
		export FTP_PROXY=""
		export ftp_proxy=$FTP_PROXY
	fi
	if [[ $https_host != "" ]]; then
		export HTTPS_PROXY="https://${http_auth_user}:${http_auth_password}@${https_host}:${https_port}/"
		export https_proxy=$HTTPS_PROXY
	else
		export HTTPS_PROXY=""
		export https_proxy=$HTTPS_PROXY
	fi
	if [[ $socks_host != "" ]]; then
		export SOCKS_PROXY="socks://${http_auth_user}:${http_auth_password}@${socks_host}:${socks_port}/"
		export socks_proxy=$SOCKS_PROXY
	else
		export SOCKS_PROXY=""
		export socks_proxy=$SOCKS_PROXY
	fi
	if [[ $ignore_hosts != "['localhost', '127.0.0.0/8']" ]]; then
		export NO_PROXY="$ignore_hosts"
		export no_proxy=$NO_PROXY
	else
		export NO_PROXY=''
		export no_proxy=$NO_PROXY	
	fi
else
	echo "non hai effettuato una scelta..."
	exit 0
fi
