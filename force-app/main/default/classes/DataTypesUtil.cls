public with sharing class DataTypesUtil {
    
    private static Map<String, Data_Type_Setting__mdt> mapDataTypes;
    private static Map<String, Data_Type_Setting__mdt> mapDataTypesByLightningInputType;

    public static String getLightningInputType(
        String dataType
    ) {
        if (mapDataTypes == null) {
            cacheDataTypeSettings();
        }
        return mapDataTypes.get(dataType)?.Lightning_Input_Type__c;
    }

    public static String getDataTypeFromLightningInputType(
        String lightningDataType
    ) {
        if (mapDataTypesByLightningInputType == null) {
            cacheDataTypeSettings();
        }
        return mapDataTypesByLightningInputType.get(lightningDataType)?.Data_Type__c;
    }

    private static void cacheDataTypeSettings() {
        mapDataTypes = new Map<String, Data_Type_Setting__mdt>();
        mapDataTypesByLightningInputType = new Map<String, Data_Type_Setting__mdt>();
        List<Data_Type_Setting__mdt> lstSettings = Data_Type_Setting__mdt.getAll().values();
        for (Data_Type_Setting__mdt dts : lstSettings) {
            mapDataTypes.put(dts.Data_Type__c, dts);
            mapDataTypesByLightningInputType.put(dts.Lightning_Input_Type__c, dts);
        }
    }

}