Class ICacheRepository {

    [string] GetByKey([string] $key) {
        Throw "Method Not Implemented";
    }

    [void] Set([string] $key, `
        [string] $value) {
        Throw "Method Not Implemented";
    }

    [void] RemoveByKey([string] $key) {
        Throw "Method Not Implemented";
    }

    [void] Flush() {
        Throw "Method Not Implemented";
    }

    [array] GetAll([string] $prefix) {
        Throw "Method Not Implemented";
    }
}