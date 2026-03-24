# BDTI_Libri
Trabalho de grupo de BDTI - rede social Libri

# Descrição
O Libri é uma mini rede social para leitores, desenvolvida no âmbito da unidade curricular de Big Data Technologies I - BDTI.

A plataforma permite:
- criação de perfis de utilizador
- partilha de leituras
- sistema de seguidores
- feed temporal
- interações (likes e notificações)

O foco do projeto é a modelação de dados e o uso de tecnologias NoSQL.

---

# Tecnologias Utilizadas

- **MongoDB** – armazenamento principal (utilizadores e publicações)
- **Cassandra** – gestão do feed e relações de seguidores
- **Redis** – gestão de likes e notificações em tempo real

---

# Preparação do Ambiente

  # Iniciar Docker
    # Iniciar MongoDB (atualizem o nome do container e porta)
    docker run -d --name mongo -p 27017:27017 mongo:7
    docker exec -i mongo mongosh < mongodb_libri.js
    
    # Iniciar Cassandra (atualizem o nome do container e porta)
    docker run -d --name cassandra -p 9042:9042 cassandra:4.1
    docker exec -i cassandra cqlsh < console_cassandra_social_libri_1.3.sql

    # Iniciar Redis (atualizem o nome do container e porta)
    docker run -d --name redis -p 6379:6379 redis:7-alpine
    docker exec -i redis redis-cli < redis_libri.sql

# Fluxos principais

    - Criação de publicação
    O post é guardado no MongoDB
    É distribuído para os seguidores no Cassandra (fan-out on write)
    O Redis inicializa o contador de likes
    
    - Feed do utilizador
    Cassandra devolve o feed ordenado
    Redis fornece número de likes
    MongoDB fornece detalhes do post (quando necessário)
    
    - Interações (Likes)
    Redis regista utilizadores que deram like
    Redis mantém contador de likes

  
