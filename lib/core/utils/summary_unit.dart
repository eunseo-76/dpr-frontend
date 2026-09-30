const _recycleTeamFactoryId = 7;

String summaryUnitNameFor(int? factoryId) =>
    factoryId == _recycleTeamFactoryId ? 'PNL' : 'M2';

bool isUnitNamed(String unitName, String targetUnitName) =>
    unitName.toUpperCase() == targetUnitName.toUpperCase();
