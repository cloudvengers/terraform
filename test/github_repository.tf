provider "github" {
    token = ""
}

resource "github_repository" "example" {
    name = "test1"
}