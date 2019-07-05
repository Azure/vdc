Class IStateRepository {

    [void] SaveResourceState([object] $entity) {
        Throw "Method Not Implemented";
    }

    [void] SaveResourceStateAndDeploymentNameMapping ([object] $entity) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceStateById([object] $id) {
        Throw "Method Not Implemented";
    }

    [object] GetResourceStateByFilters([object[]] $filters) {
        Throw "Method Not Implemented";
    }

    [object] GetLatestDeploymentMapping([object[]] $filters) {
        Throw "Method Not Implemented";
    }
}