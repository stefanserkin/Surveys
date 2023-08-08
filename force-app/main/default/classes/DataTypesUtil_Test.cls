@IsTest
private class DataTypesUtil_Test {
    
    @IsTest
    static void testGetLightningInputType() {
        Data_Type_Setting__mdt setting = Data_Type_Setting__mdt.getAll().values().get(0);
        String lightningInputType;
        Test.startTest();
        lightningInputType = DataTypesUtil.getLightningInputType(setting.Data_Type__c);
        Test.stopTest();
        Assert.areEqual(setting.Lightning_Input_Type__c, lightningInputType, 'Received incorrect lightning input type');
    }

    @IsTest
    static void testGetDataTypeFromLightningInputType() {
        Data_Type_Setting__mdt setting = Data_Type_Setting__mdt.getAll().values().get(0);
        String strDataType;
        Test.startTest();
        strDataType = DataTypesUtil.getDataTypeFromLightningInputType(setting.Lightning_Input_Type__c);
        Test.stopTest();
        Assert.areEqual(setting.Data_Type__c, strDataType, 'Received incorrect data type');
    }

}