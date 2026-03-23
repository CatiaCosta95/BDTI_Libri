//Limpar dados (sempre que necessário)
db.users.drop();
db.posts.drop();

//Inserir vários users
db.users.insertMany([
  {
    username: "bruno_tech",
    email: "bruno@libri.pt",
    location: "Lisboa",
    profile: {
      bio: "Entusiasta de ficção científica e café.",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Bruno",
      currently_reading: "Duna",
      reading_goal: 12
    },
    created_at: new Date()
  },
  {
    username: "carla_books",
    email: "carla@libri.pt",
    location: "Coimbra",
    profile: {
      bio: "A ler o meu caminho pelo mundo.",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Carla",
      currently_reading: "Cem Anos de Solidão",
      reading_goal: 30
    },
    created_at: new Date()
  },
  {
    username: "diogo_viana",
    email: "diogo@libri.pt",
    location: "Braga",
    profile: {
      bio: "Colecionador de edições raras.",
      avatar_url: "https://api.dicebear.com/7.x/avataaars/svg?seed=Diogo",
      currently_reading: "1984",
      reading_goal: 15
    },
    created_at: new Date()
  }
]);

//Procurar os IDs e guardar em variáveis
const brunoID = db.users.findOne({username: "bruno_tech"})._id;
const carlaID = db.users.findOne({username: "carla_books"})._id;
const diogoID = db.users.findOne({username: "diogo_viana"})._id;

//Criar a collection posts
db.createCollection("posts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["author_id", "book_title", "status", "content", "rating", "created_at"],
      properties: {
        author_id: { bsonType: "objectId" },
        book_title: { bsonType: "string" },
        author_book: { bsonType: "string" },
        content: { bsonType: "string", minLength: 10 },
        rating: { bsonType: "int", minimum: 1, maximum: 5 },
        status: { enum: ["Lendo", "Concluído", "Quero Ler", "Abandonei"] },
        created_at: { bsonType: "date" },
        // Estrutura dos Comentários Embedding
        comments: {
          bsonType: "array",
          items: {
            bsonType: "object",
            required: ["user_id", "username", "text", "created_at"],
            properties: {
              user_id: { bsonType: "objectId" },
              username: { bsonType: "string" },
              text: { bsonType: "string" },
              created_at: { bsonType: "date" }
            }
          }
        }
      }
    }
  }
});

//Insert inicial de posts
db.posts.insertMany([
  {
    author_id: db.users.findOne({username: "bruno_tech"})._id,
    book_title: "Duna",
    author_book: "Frank Herbert",
    content: "A política e a ecologia de Arrakis são fascinantes.",
    rating: NumberInt(5),
    status: "Lendo",
    created_at: new Date(),
    comments: [] // Inicializa vazio
  },
  {
    author_id: db.users.findOne({username: "carla_books"})._id,
    book_title: "Cem Anos de Solidão",
    author_book: "Gabriel García Márquez",
    content: "Um clássico que exige atenção absoluta.",
    rating: NumberInt(5),
    status: "Concluído",
    created_at: new Date(),
    comments: []
  }
]);

//Procurar IDs dos Posts pe guardar em variáveis
const postDunaId = db.posts.findOne({ book_title: "Duna" })._id;
const postSolidaoId = db.posts.findOne({ book_title: "Cem Anos de Solidão" })._id;

//Insert de comentário - O Diogo comenta o post do Bruno sobre "Duna"
db.posts.updateOne(
  { _id: postDunaId },
  {
    $push: {
      comments: {
        user_id: db.users.findOne({username: "diogo_viana"})._id,
        username: "diogo_viana", // Desnormalização: guardamos o nome para leitura rápida
        text: "Mal posso esperar para ver a adaptação no cinema!",
        created_at: new Date()
      }
    }
  }
);

//Insert de comentário - A Carla também comenta o post do Bruno
db.posts.updateOne(
  { _id: postDunaId },
  {
    $push: {
      comments: {
        user_id: db.users.findOne({username: "carla_books"})._id,
        username: "carla_books",
        text: "É o meu livro favorito de sci-fi!",
        created_at: new Date()
      }
    }
  }
);

//Index
//Garantir que não há username iguais
db.users.createIndex({ username: 1 }, { unique: true });

//Index author_id + date - acelera a visualização do perfil do utilizador
db.posts.createIndex({ author_id: 1, created_at: -1 });

//Index de texto para pesquisa de livros - permite a pesquisa por palavras soltas e não o texto exato
db.posts.createIndex({ book_title: "text", author_book: "text" });

//Confirmar a criação dos index
db.posts.getIndices();

//Pesquisas
//Top Comentadores - Quem são os utilizadores que mais comentam?
db.posts.aggregate([
  { $unwind: "$comments" }, // Parte o array em documentos individuais
  { $group: {
      _id: "$comments.username",
      total_comentarios: { $sum: 1 }
  }},
  { $sort: { total_comentarios: -1 } },
  { $limit: 5 }
]);

//Métrica de Objetivos - Relaciona os livros concluídos com o objetivo de leitura do perfil do utilizador
db.users.aggregate([
  {
    $lookup: {
      from: "posts",
      localField: "_id",
      foreignField: "author_id",
      as: "meus_posts"
    }
  },
  {
    $project: {
      username: 1,
      objetivo: "$profile.reading_goal",
      livros_concluidos: {
        $size: {
          $filter: {
            input: "$meus_posts",
            as: "post",
            cond: { $eq: ["$$post.status", "Concluído"] }
          }
        }
      }
    }
  }
]);

//Análise de tendências locais - Quais os livros mais populares por localização?
db.users.aggregate([
  {
    $lookup: {
      from: "posts",
      localField: "_id",
      foreignField: "author_id",
      as: "posts_info"
    }
  },
  { $unwind: "$posts_info" },
  {
    $group: {
      _id: { local: "$location", livro: "$posts_info.book_title" },
      contagem: { $sum: 1 }
    }
  },
  { $sort: { "_id.local": 1, contagem: -1 } }
]);

