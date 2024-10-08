import:py os;
import:py from langchain_community.document_loaders {PyPDFDirectoryLoader}
import:py from langchain_text_splitters {RecursiveCharacterTextSplitter}
import:py from langchain.schema.document {Document}
import:py from langchain_community.embeddings.ollama {OllamaEmbeddings}
import:py from langchain_community.vectorstores.chroma {Chroma}

obj RagEngine {
    has file_path: str = "docs";
    has chroma_path: str = "chroma";

    # method runs automatically upon initialization, loading documents, splitting them into chunks,
    # and adding them to the vector database
    can postinit {
        documents: list = self.load_documents();
        chunks: list = self.split_documents(documents);
        self.add_to_chroma(chunks);
    }

    # method loads the documents from the specified directory
    can load_documents {
        document_loader = PyPDFDirectoryLoader(self.file_path);
        return document_loader.load();
    }

    # method splits the documents into chunks
    can split_documents(documents: list[Document]) {
        text_splitter = RecursiveCharacterTextSplitter(chunk_size=800,
        chunk_overlap=80,
        length_function=len,
        is_separator_regex=False);
        return text_splitter.split_documents(documents);
    }

    # method that uses the OllamaEmbeddings model to create embeddings for the document chunks
    can get_embedding_function {
        embeddings = OllamaEmbeddings(model='nomic-embed-text');
        return embeddings;
    }

    # method that assigns IDs to each chunk using format Page Source : Page Number : Chunk Index
    can add_chunk_id(chunks: str) {
        last_page_id = None;
        current_chunk_index = 0;

        for chunk in chunks {
            source = chunk.metadata.get('source');
            page = chunk.metadata.get('page');
            current_page_id = f'{source}:{page}';

            if current_page_id == last_page_id {
                current_chunk_index +=1;
            } else {
                current_chunk_index = 0;
            }

            chunk_id = f'{current_page_id}:{current_chunk_index}';
            last_page_id = current_page_id;

            chunk.metadata['id'] = chunk_id;
        }

        return chunks;
    }

    # method checks for existing documents in the database and only adds new chunks to 
    # avoid duplication
    can add_to_chroma(chunks: list[Document]) {
        db = Chroma(persist_directory=self.chroma_path, embedding_function=self.get_embedding_function());
        chunks_with_ids = self.add_chunk_id(chunks);

        existing_items = db.get(include=[]);
        existing_ids = set(existing_items['ids']);

        new_chunks = [];
        for chunk in chunks_with_ids {
            if chunk.metadata['id'] not in existing_ids {
                new_chunks.append(chunk);
            }
        }

        if len(new_chunks) {
            print('adding new documents');
            new_chunk_ids = [chunk.metadata['id'] for chunk in new_chunks];
            db.add_documents(new_chunks, ids=new_chunk_ids);
        } else {
            print('no new documents to add');
        }
    }

    # method takes a query and returns the most relevant chunks based on similarity search
    can get_from_chroma(query: str,chunck_nos: int=5) {
        db = Chroma(
            persist_directory=self.chroma_path,
            embedding_function=self.get_embedding_function()
        );
        results = db.similarity_search_with_score(query,k=chunck_nos);
        return results;
    }
}