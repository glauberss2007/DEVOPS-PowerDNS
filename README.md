# oci-vin-dns-env

![image](https://user-images.githubusercontent.com/22028539/131381195-22058b2b-20d3-4f35-a4b4-75b8046ebc7b.png)

Ambiente DNS da OCI de vinhedos

PowerDNS é um servidor de nomes poderoso e de alto desempenho. É uma alternativa ao BIND DNS e pode utilizar MariaDB, MySQL ou Oracle para armazenar registros. O PowerDNS é executado na maioria dos sistemas operacionais baseados em UNIX e é usado para hospedar domínios usando DNSSEC. Ele usa um programa separado chamado PowerDNS Recursor como o servidor DNS de resolução. PowerDNS-Admin é uma interface da web avançada para o PDNS, utilizado para gerenciar zonas e registros por meio de um navegador da web.

Neste projeto utilizamos o terraform para subir os recurses de redes e um script para instalar e configurar o PDNS com MariaDB em SO CentOS 8.

Topologia final:

TODO Desenho da topologia OCI



