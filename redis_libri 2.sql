-- Limpar
DEL "like:p1:users" "like:p1:users" "like:p2:users" "ranking:livros" "like:p1" "like:p2" "user:notifs:bruno_tech" "user:notifs:carla_books"

-- Registo de "Quem deu like no quê" (Sets) e contador de likes (Hash)
SADD "like:p1:users" "carla_books"
HINCRBY "like:p1" "count" 1
SADD "like:p1:users" "diogo_viana"
HINCRBY "like:p1" "count" 1
SADD "like:p2:users" "bruno_tech"
HINCRBY "like:p2" "count" 1

-- A mesma pessoa não pode dar mais do que 1 like, logo aqui vai dar 0
SADD "like:p1:users" "carla_books"

-- Saber quantos likes tem o post
--retorna quem deu likes
SMEMBERS "like:p1:users"
--retorna o nr de likes (mais rapido)
HGET "like:p1" "count"

SMEMBERS "like:p2:users"
HGET "like:p2" "count"

-- notificações (Sorted Set)
-- notifica o Bruno que a Carla e o Diogo deram like
ZADD "user:notifs:bruno_tech" 1710950000 "{\"type\": \"like\", \"from\": \"carla_books\", \"post\": \"Duna\"}"
ZADD "user:notifs:bruno_tech" 1710951000 "{\"type\": \"like\", \"from\": \"diogo_viana\", \"post\": \"Duna\"}"
EXPIRE "user:notifs:bruno_tech" 604800
-- notifica a Carla que o Bruno deu like
ZADD "user:notifs:carla_books" 1710970000 "{\"type\": \"like\", \"from\": \"bruno_tech\", \"post\": \"Cem Anos de Solidão\"}"
EXPIRE "user:notifs:carla_books" 604800

--vai listar as notificações que são apresentadas e apresenta a partir da mais recente
ZREVRANGE "user:notifs:bruno_tech" 0 -1 WITHSCORES
ZREVRANGE "user:notifs:carla_books" 0 -1 WITHSCORES

-- Ranking dos livros (Sorted Set)
ZINCRBY "ranking:livros" 7 "Duna"
ZINCRBY "ranking:livros" 5 "Cem Anos de Solidão"
ZINCRBY "ranking:livros" 10 "1984"

-- Top dos Livros, descrscente
ZREVRANGE "ranking:livros" 0 -1 WITHSCORES
