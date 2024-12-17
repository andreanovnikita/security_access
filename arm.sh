#######
PATHTOCA=/root/CA
PAPKACA=easy-rsa
#######
protectmodule () {
	checksudo
	clear
	devname
        echo
	echo "Секция: Управление модулями доступа"
        echo "Выберите действие:"
        echo "   1) Изменить ПИН-код пользователя (PIN)"
        echo "   2) Изменить ПИН-код администратора (SO/PUK)"
        echo "   3) Отформатировать модуль защиты"
        echo "   4) Проверка подключенных модулей защиты"
        echo "   5) Запись ключа доступа в модуль защиты"
	echo "   6) Получить список сертификатов в модуле защиты"
        echo "   99) Выход из секции"
        read -p "Выбор: " option
        case "$option" in
                1)
                        checksudo
			clear
                        read -p "Введите используемый слот:" slot
			echo -e "\033[33mОбработка...\033[0m"
			sleep 2
			changepinuser
                        exit
                ;;
                2)
                        checksudo
                        clear
                        read -p "Введите используемый слот:" slot
                        echo -e "\033[33mОбработка...\033[0m"
                        sleep 2
                        changepinadmin
                        exit
		;;
		3)
                        checksudo
                        clear
                        read -p "Введите используемый слот:" slot
                        echo -e "\033[33mОбработка...\033[0m"
                        sleep 2
                        changepinadmin
                        exit
		;;
		4)	checksudo
			clear
			sleep 2
			lsusb
		;;
		5)
		;;
		6)      checksudo
                        clear
                        read -p "Введите используемый слот: " slot
                        echo -e "\033[33mОбработка...\033[0m"
                        sleep 2
		        read -p "Введите пин-код пользователя: " pin
			echo -e "\033[32mСписок сертификатов: \033[0m"
			pkcs11-tool --module librtpkcs11ecp.so --login --pin "$pin" --list-objects --type cert
                        exit

		;;
		*)
		;;
		esac
}
changepinuser () {
	clear
	echo "Установка ПИН-кода пользователя (ПИН)"
        read -p "Введите старый пин-код: " oldpin
	read -p "Введите новый пин-код: " newpin
	read -p "Повторите новый пин-код: " newpin_check
	if [ "$newpin_check" = "$newpin" ]; then
		clear
		uac
		clear
		echo -e "\033[33mСистема ответила следующее:\033[0m"
		echo ""
		pkcs11-tool --module librtpkcs11ecp.so --slot-index "$slot" --login --pin "$oldpin" --change-pin --new-pin "$newpin" 
	else
		echo -e "\033[31mОтклонено: Неверно введён ПИН-код!\033[0m"
	fi
	exit
}

checkmount () {
#if [ -e $PATHTOCA ]; then
#	echo -e ""
#else
#        echo -e "\033[31mОтклонено: УЦ не смонтирован!\033[0m"
#	sleep 3
#	mountmode
#	exit
#fi
echo ""
}

mountmode () {
        echo ""
        echo ""
	clear
	devname
	echo ""
        echo "Выберите действие:"
        echo "   1) Смонтировать УЦ"
	echo "   2) Размонтировать УЦ"
        echo "   0) Выйти"
        read -p "Выбор: " techoption
        case "$techoption" in
                1)
		checksudo_mm
		echo -e "\033[33mСледуйте инструкциям на экране.\033[0m"
		sudo veracrypt /root/CAlist /root/CA -k /root/CAmodule
		if [ -e $PATHTOCA ]; then
	        echo -e "\033[32mОперация выполнена.\033[0m"
	else
        	echo -e "\033[31mОтклонено: Монтирование не выполнено!\033[0m"
        	exit
	fi
	exit

		;;
		2)
		checksudo_mm
                echo -e "\033[33mСледуйте инструкциям на экране.\033[0m"
		sudo veracrypt --dismount /root/CAlist
                if [ -e $PATHTOCA ]; then
                echo -e "\033[31mОтклонено: Размонтирование не выполнено!\033[0m"
        else
                echo -e "\033[32mОперация выполнена.\033[0m"
                exit
        fi
        exit
		;;
		*)
		exit
		;;
esac
}


devname () {
echo "======================================================"
echo "АРМ "Сеть - сисадминам""
echo "Удостоверяющий центр: $PAPKACA"
echo -e "\033[33mРазработчик: Андреянов Никита Сергеевич\033[0m"
echo -e "\033[33mПрава администратора обязательны.\033[0m"
echo -e "\033[31mНесанкционированный доступ преследуется по закону!\033[0m"
echo "======================================================"
}

genrevoke () {
clear
checksudo
echo ""
echo -e "\033[32mВведите пароль УЦ для отзыва сертификата.\033[0m"
cd $PATHTOCA/$PAPKACA
bash ./easyrsa --batch revoke "$client"
sleep 2
clear
checksudo
echo ""
echo -e "\033[32mВведите пароль УЦ для генерации CRL.\033[0m"
rm pki/crl.pem
EASYRSA_CRL_DAYS=3650 bash ./easyrsa gen-crl
if [ -e $PATHTOCA/$PAPKACA/pki/crl.pem ]; then
        echo -e "\033[32mОперация выполнена.\033[0m"
else
        echo -e "\033[31mОтклонено: Операция CRL не выполнена.\033[0m"
        exit
fi
exit

echo
echo -e "\033[32mСертификат $client отозван.\033[0m"
exit
}
#####################################################################

revokecrt () {
clear
checksudo
number_of_clients=$(tail -n +2 $PATHTOCA/$PAPKACA/pki/index.txt | grep -c "^V")
if [[ "$number_of_clients" = 0 ]]; then
        echo
        echo -e "\033[31mОтклонено: Нет сертификатов, которые можно отозвать!\033[0m"
        exit
fi
echo
echo -e "\033[33mНа экране представлен список сертификатов.\033[0m"
echo -e "\033[33mПожалуйста, выберите нужный для отзыва.\033[0m"
ls $PATHTOCA/$PAPKACA/pki/issued
echo ""
readname_disablechecks
if [ -e $PATHTOCA/$PAPKACA/pki/issued/$client.crt ]; then
	checksudo
	uac
	genrevoke
exit
else
	echo -e "\033[31mОтклонено: Сертификат не обнаружен!.\033[0m"
	exit
fi
	exit
}
######################################################################

gencsr () {
	checksudo
        echo ""
	cd $PATHTOCA/$PAPKACA
        bash ./easyrsa gen-req "$client" nopass
if [ -e $PATHTOCA/$PAPKACA/pki/reqs/$client.req ]; then
	echo -e "\033[32mCSR для сертификата $client создан.\033[0m"
	exit
else
	echo -e "\033[31mОтклонено: CSR для сертификата $client не обнаружен!\033[0m"
        exit
	fi
	exit
}

readname_disablechecks () {
checksudo
echo ""
if [ -e $PATHTOCA/$PAPKACA/pki/private/ca.key ]; then
echo "Введите имя сертификата (CN):"
read -p "Сертификат: " unsanitized_client
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
else
        echo
        echo -e "\033[31mОтклонено: УЦ не смонтирован!\033[0m"
        exit
        fi

}

readname () {
checksudo
echo ""
if [ -e $PATHTOCA/$PAPKACA/pki/private/ca.key ]; then
echo "Введите имя сертификата (CN):"
read -p "Сертификат: " unsanitized_client
client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
while [[ -z "$client" || -e $PATHTOCA/$PAPKACA/pki/issued/"$client".crt ]]; do
        echo -e "\033[31mОтклонено: сертификат уже подписан!\033[0m"
        exit
done
else
        echo
        echo -e "\033[31mОтклонено: УЦ не смонтирован!\033[0m"
        exit
        fi

}

signcsr () {
checksudo
if [ -e $PATHTOCA/$PAPKACA/pki/reqs/$client.req ]; then
	uac
	checksudo
	echo -e "\033[33mСертификат: $client\033[0m"
        echo -e "\033[33mСрок действия: $dayssign\033[0m"
        echo -e "\033[33mЕсли данные корректны, введите слово yes, а затем пароль УЦ.\033[0m"
	echo ""
        cd $PATHTOCA/$PAPKACA
        EASYRSA_CERT_EXPIRE=$dayssign bash ./easyrsa sign-req client "$client"
        new_client
        echo ""
        exit
else
        echo
	echo -e "\033[31mОтклонено: сертификат не создан!\033[0m"
        fi
}

uac () {
echo "==================================="
echo -e "\033[31mЗапрос подтверждения\033[0m"
echo "==================================="
read -p "Подтвердите выполнение операции: [Y/n]: " item
case "$item" in
    y|Y) echo ""
        ;;
    n|N) echo -e "\033[31mОтклонено: отказ от операции!\033[0m"
        exit 1
        ;;
    *) echo -e "\033[31mОтклонено: некорректный ввод!\033[0m"
        exit 1
        ;;
esac
}

checksudo () {
         echo -e "\033[33mПроизводится проверка...\033[0m"
         sleep 2
         if [ "$EUID" -ne 0 ]
         then    echo -e "\033[31mОтклонено. Нет прав администратора. (EUID ≠ 0)\033[0m"
         exit
         fi
         echo -e "\033[32m \033[0m"
	 checkmount
}
checksudo_mm () {
         echo -e "\033[33mПроизводится проверка...\033[0m"
         sleep 2
         if [ "$EUID" -ne 0 ]
         then    echo -e "\033[31mОтклонено. Нет прав администратора. (EUID ≠ 0)\033[0m"
         exit
         fi
         echo -e "\033[32m \033[0m"
}

new_client () {
        checksudo
        if [ -e $PATHTOCA/$PAPKACA/pki/issued/$client.crt ]; then
        	putout
        else
                echo -e "\033[31mОтклонено: сертификат не обнаружен!\033[0m"
                exit
	fi
}

putout () {
        {
        cat $PATHTOCA/client-common-server-data.txt
        echo "<ca>"
        cat $PATHTOCA/$PAPKACA/pki/ca.crt
        echo "</ca>"
        echo "<cert>"
        sed -ne '/BEGIN CERTIFICATE/,$ p' $PATHTOCA/$PAPKACA/pki/issued/"$client".crt
        echo "</cert>"
        echo "<key>"
        cat $PATHTOCA/$PAPKACA/pki/private/"$client".key
        echo "</key>"
        } > $PATHTOCA/$PAPKACA/outputcrt/"$client".ovpn
        echo -e "\033[32mСертификат $client выдан.\033[0m"
	echo -e "\033[32mПуть: $PATHTOCA/$PAPKACA/outputcrt/"$client".ovpn\033[0m"
}


	clear
	checksudo
	clear
	devname
	echo
	echo "Выберите действие:"
	echo "   1) Создать CSR клиента"
	echo "   2) Отозвать клиента"
        echo "   3) Подписать сертификат, установив срок действия: 1 день"
        echo "   4) Подписать сертификат, установив срок действия: 5 дней"
        echo "   5) Подписать сертификат, установив срок действия: 10 дней"
        echo "   6) Подписать сертификат, установив срок действия: 30 дней"
        echo "   7) Подписать сертификат, установив срок действия: 50 дней"
        echo "   8) Подписать сертификат, установив срок действия: 60 дней"
	echo "   9) Подписать сертификат, установив срок действия: 90 дней"
        echo "   10) Подписать сертификат, установив срок действия: 180 дней"
        echo "   11) Подписать сертификат, установив срок действия: 365 дней"
        echo "   12) Подписать сертификат, установив срок действия: 3650 дней"
        echo "   13) Перегенерация crl.pem"
        echo "   14) Управление модулями безопасности"
	echo "   15) Импорт CSR"
	echo "   98) Монтирование"
	echo "   99) Повтор команды выдачи сертификата"
	read -p "Выбор: " option
	case "$option" in
		1)
                        clear
			readname
			gencsr
			exit
                ;;
		2)

                         clear
			 revokecrt
			 exit
                ;;

                3)
                        clear
			dayssign=1
			readname
			signcsr
                        exit
                ;; 
                4)
                        clear
                        dayssign=5
                        readname
                        signcsr
                        exit
                ;;
                5)
                        clear
                        dayssign=10
                        readname
                        signcsr
                        exit
                ;;
                6)
                        clear
                        dayssign=30
                        readname
                        signcsr
                        exit
                ;;
                7)
                        clear
                        dayssign=50
                        readname
                        signcsr
                        exit
                ;;
                8)
                        clear
                        dayssign=60
                        readname
                        signcsr
                        exit
                ;;
                9)
                        clear
                        dayssign=90
                        readname
                        signcsr
                        exit
                ;;
                10)
                        clear
                        dayssign=180
                        readname
                        signcsr
                        exit
                ;;
                11)
                        clear
                        dayssign=365
                        readname
                        signcsr
                        exit
                ;;
                12)
                        clear
                        dayssign=3650
                        readname
                        signcsr
                        exit
                ;;
		14)
			protectmodule
			exit
		;;
                13)
		      checksudo
		      uac
	              clear
                                if [ -e $PATHTOCA/$PAPKACA/pki/private/ca.key ]; then
                                echo -e "\033[32mВведите пароль УЦ для генерации CRL.\033[0m"
		                echo ""
				cd $PATHTOCA/$PAPKACA
				rm pki/crl.pem
		                EASYRSA_CRL_DAYS=3650 bash ./easyrsa gen-crl
                        else
				echo -e "\033[31mОтклонено: УЦ не смонтирован!\033[0m"
				exit
                        fi
                                if [ -e $PATHTOCA/$PAPKACA/pki/crl.pem ]; then
				echo -e "\033[32mОперация выполнена.\033[0m"
			else
				echo -e "\033[31mОперация не выполнена.\033[0m"
				exit
			fi
			exit

               ;;
		15) 
			checksudo
			clear
			read -p "Укажите путь к CSR: " csr
			read -p "Имя сертификата: " name
			uac
			cd $PATHTOCA/$PAPKACA
			bash ./easyrsa import-req "$csr" "$name"
		;;
	        98) mountmode
		;;

		15)
		changepinuser
		;;

               99)          
                        clear
              		readname_disablechecks
			new_client
			exit
                ;;

	         *)
			exit
		;;
     esac
