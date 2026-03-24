//O MongoDB armazena as publicações originais, enquanto o Cassandra
-- mantém uma versão desnormalizada dos dados para suportar o feed com baixa latência.CREATE KEYSPACE IF NOT EXISTS social

USE social;

TRUNCATE timeline;
TRUNCATE followers_by_user;
TRUNCATE following_by_user;

CREATE KEYSPACE IF NOT EXISTS social
WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

// Criar Tabela Timeline
CREATE TABLE IF NOT EXISTS timeline (
  user_id uuid,
  post_id timeuuid,
  author_id uuid,
  author_username text,
  book_title text,
  author_book text,
  content text,
  rating int,
  status text,
  created_at timestamp,
  PRIMARY KEY (user_id, post_id)
) WITH CLUSTERING ORDER BY (post_id DESC);

// Criar Tabela Followers by user
CREATE TABLE IF NOT EXISTS followers_by_user (
  user_id uuid,
  follower_id uuid,
  follower_username text,
  followed_at timestamp,
  PRIMARY KEY (user_id, follower_id)
);

// Criar Tabela Following by user
CREATE TABLE IF NOT EXISTS following_by_user (
  user_id uuid,
  followed_id uuid,
  followed_username text,
  followed_at timestamp,
  PRIMARY KEY (user_id, followed_id)
);

DESCRIBE TABLES;

// Inserir Folowers
INSERT INTO followers_by_user (
  user_id, follower_id, follower_username, followed_at
) VALUES (
  11111111-1111-1111-1111-111111111111,
  22222222-2222-2222-2222-222222222222,
  'bruno_tech',
  toTimestamp(now())
);

// Inserir Folowed
INSERT INTO following_by_user (
  user_id, followed_id, followed_username, followed_at
) VALUES (
  22222222-2222-2222-2222-222222222222,
  11111111-1111-1111-1111-111111111111,
  'carla_books',
  toTimestamp(now())
);



// Inserir post (1) da Carla no feed da Patrícia.
INSERT INTO timeline (
  user_id, post_id, author_id, author_username,
  book_title, author_book, content, rating, status, created_at
) VALUES (
  22222222-2222-2222-2222-222222222222,
  now(),
  11111111-1111-1111-1111-111111111111,
  'carla_books',
  'Duna',
  'Frank Herbert',
  'A política e a ecologia de Arrakis são fascinantes.',
  5,
  'Lendo',
  toTimestamp(now())
);

//Inserir outro(2) post da Carla no feed do Bruno.
  INSERT INTO timeline (
  user_id, post_id, author_id, author_username,
  book_title, author_book, content, rating, status, created_at
) VALUES (
  22222222-2222-2222-2222-222222222222,
  now(),
  11111111-1111-1111-1111-111111111111,
  'carla_books',
  '1984',
  'George Orwell',
  'Uma leitura intensa sobre controlo, vigilância e poder.',
  5,
  'Concluído',
  toTimestamp(now())
);
// Inserir outro(3) post da Carla no feed do Bruno
INSERT INTO timeline (
  user_id, post_id, author_id, author_username,
  book_title, author_book, content, rating, status, created_at
) VALUES (
  22222222-2222-2222-2222-222222222222,
  now(),
  11111111-1111-1111-1111-111111111111,
  'carla_books',
  'Orgulho e Preconceito',
  'Jane Austen',
  'Um clássico envolvente sobre relações, expectativas e sociedade.',
  4,
  'Quero Ler',
  toTimestamp(now())
);

//Posts presentes no feed do Bruno:
SELECT post_id, author_username, book_title, status, created_at
FROM timeline
WHERE user_id = 22222222-2222-2222-2222-222222222222;

//Feed realista - Na app não queremos carregar os posts todos. Carrega no feed posts ordenados pelo post_id até um limite.
SELECT post_id, author_username, book_title, status, created_at
FROM timeline
WHERE user_id = 22222222-2222-2222-2222-222222222222
LIMIT 2;


// Seguidores da Carla - "Quem segue a Carla?"
SELECT * FROM followers_by_user
WHERE user_id = 11111111-1111-1111-1111-111111111111;

// Seguidos do Bruno - "Quem o Bruno segue?"
SELECT * FROM following_by_user
WHERE user_id = 22222222-2222-2222-2222-222222222222;

// Feed/Mural do Bruno
SELECT * FROM timeline
WHERE user_id = 22222222-2222-2222-2222-222222222222;


//A tabela timeline permite recuperar eficientemente as publicações mais recentes de um utilizador,
-- utilizando timeuuid como clustering key ordenada de forma decrescente, garantindo leitura sequencial otimizada.
-- O uso de timeuuid permite ordenação temporal eficiente sem necessidade de sorting adicional.


//fan-out on write: Quando a Carla faz um post → esse post é inserido na timeline de todos os seguidores

//O feed é implementado com uma estratégia de fan-out on write, onde cada nova publicação é distribuída pelas timelines dos seguidores,
-- permitindo leituras eficientes sem necessidade de agregação em tempo real.


