import chromadb
from chromadb import Settings


def test_chroma():
    client = chromadb.HttpClient(host="localhost", port=8000)
    client.heartbeat()
    # collection = client.create_collection("all1-my-documents")


if __name__ == '__main__':
    test_chroma()