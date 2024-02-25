#!/bin/bash


mensaje="Mensaje diario automatizado control Nagios"

#Anadir manualmente (Hostname IP Puerto Clave NCPA)
#host0=("example.com" "127.0.0.0" "22" "c")
#array_hosts=("${host0[@]}")

#Funcion que comprueba los host y anade los resultados al final de un mensaje
check_command() {

local command="$1"

if $(echo "$command") | grep -q "OK"; then
    echo "pass"
elif $(echo "$command") | grep -q "WARNING"; then
    echo "problem"
else
    echo "failed"
fi
}

check_host(){
local hostname="$2"
local puerto="$3"
local ncpa="$4"

#Comprobamos si esta en linea haciendo ping
host_alive=$(check_command "./check_ping -H $hostname -w 100.0,20% -c 500.0,60%")
host_ssh=$(check_command "./check_ssh  -4  -p $puerto  $hostname")
host_https=$(check_command "./check_http -H $hostname -S -w 5 -c 10")
host_disk

mensaje+="\\n El host $hostname \\n Estoy vivo:  $host_alive \\n Estoy accesible: $host_ssh \\n Estoy visible: $host_https"
}

#Funcion que escanea la carpeta escaner obtiene los datos de los host
scan_servers(){
ruta_servidores="/usr/local/nagios/etc/servers"
for file in "$ruta_servidores"/*.cfg; do
        if [ -f "$file" ]; then
                # Extraemos hostname
                hostname=$(awk '/host_name/{print $2}' "$file" | head -n 1)

                # Extraemos address
                address=$(awk '/address/{print $2}' "$file" | head -n 1)

                #Extraemos el puerto
                port=$(awk -F '!' '/check_ssh/{print $2}' "$file" | awk -F  ' ' '/-p/{print $2}'| head -n 1 )

                # Extraemos token
                token=$(awk -F '!' '/check_command/{print $2}' "$file" | awk -F ' ' '/-t/{print $2}'| tr -d "'"  | head -n 1)

                # Create an array and assign the values
                hostarr=( "$address" "$port" "$token")
                array_hosts+=("${hostarr[@]}")
        fi
done
}




# Escaneamos carpeta Servers
scan_servers

# Recorrer el array de hosts
for ((i = 0; i < ${#array_hosts[@]}; i+=3)); do
        hostname=$(($i+0))
        puerto=$(($i+1))
        clave=$(($i+2))
        check_host "$mensaje" "${array_hosts[$hostname]}" "${array_hosts[$puerto]}" "$clave" 
done
echo -e "$mensaje"
exit