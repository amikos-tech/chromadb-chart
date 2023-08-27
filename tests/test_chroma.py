import logging
import os
import uuid

import chromadb
from chromadb.utils import embedding_functions
from dotenv import load_dotenv

load_dotenv()

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s', level=logging.DEBUG)
logger = logging.getLogger(__name__)


def get_embedding_function():
    """
    Get the embedding function

    :return: Embedding function
    """

    openai_ef = embedding_functions.OpenAIEmbeddingFunction(
        model_name="text-embedding-ada-002",
        api_key=os.environ.get('OPENAI_API_KEY')
    )
    return openai_ef


sentence_transformer_ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")


def test_chroma():
    client = chromadb.HttpClient(host="34.135.246.105", port=8000)
    client.heartbeat()
    # client.reset()
    collection = client.get_or_create_collection("all1-my-documents",
                                                 embedding_function=sentence_transformer_ef)
    transf = sentence_transformer_ef(["this is a test embedding"])
    print(transf)
    # collection.add(documents=["this is a test embedding"], metadatas=[{"type": "page"}], ids=[str(uuid.uuid4())])
    # assert len(collection.get()['ids']) == 1


def test_reset():
    client = chromadb.HttpClient(host="localhost", port=8000)
    client.heartbeat()
    client.reset()


def test_auth():
    client = chromadb.HttpClient(host="localhost", port="8000", headers={"Authorization": "Token test"})
    client.heartbeat()


if __name__ == '__main__':
    test_chroma()
