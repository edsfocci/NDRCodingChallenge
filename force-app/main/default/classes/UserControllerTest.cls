@isTest
private class UserControllerTest {
   /**
    * Test to make sure that if Lead and Opp records are set up properly,
    * and their CreatedDate and CloseDate respectively are within the given
    * startDate and endDate inputs, the result should give expected outputs
    */
    @isTest
    static void testStandardSetupWorks() {
        Id testUserId = generateTestUser();

        standardSetupRecords(testUserId, 'Closed Won');

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 2, 1),
                Date.newInstance(2020, 2, 28));
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('TestUser', (String) result[0].get('salesRepName'));
        System.assertEquals(1, (Integer) result[0].get('totalLeads'));
        System.assertEquals(1, (Integer) result[0].get('totalOpps'));
        System.assertEquals(1.0000, (Decimal) result[0].get('conversionRate'));
        System.assert(Date.newInstance(2020, 2, 15+5).isSameDay(
            ((DateTime) result[0].get('latestCreatedDate')).date()));
        System.assertEquals(100.00, (Decimal) result[0].get('totalValue'));
    }

   /**
    * Test to make sure that if Lead and Opp records CreatedDate and CloseDate
    * respectively are both not within the given startDate and endDate inputs,
    * the result will have zero rows
    */
    @isTest
    static void testRecordsOutsideDateRange() {
        Id testUserId = generateTestUser();

        standardSetupRecords(testUserId, 'Closed Won');

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 3, 1),
                Date.newInstance(2020, 3, 31));
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

   /**
    * Test to make sure that if the given startDate is after the given endDate,
    * the result should have zero rows, and will not throw exceptions
    */
    @isTest
    static void testInvalidInputs() {
        Id testUserId = generateTestUser();

        standardSetupRecords(testUserId, 'Closed Won');

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 2, 28),
                Date.newInstance(2020, 2, 1));
        Test.stopTest();

        System.assertEquals(0, result.size());
    }

   /**
    * Test to make sure that if the Opp StageName is not "Closed Won",
    * that Opp record is excluded from the record count and
    * Opp aggregate calculations
    */
    @isTest
    static void testStageNotClosedWon() {
        Id testUserId = generateTestUser();

        standardSetupRecords(testUserId, 'Prospecting');

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 2, 1),
                Date.newInstance(2020, 2, 28));
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('TestUser', (String) result[0].get('salesRepName'));
        System.assertEquals(1, (Integer) result[0].get('totalLeads'));
        System.assertEquals(0, (Integer) result[0].get('totalOpps'));
        System.assertEquals(0.0000, (Decimal) result[0].get('conversionRate'));
        System.assertEquals(null, result[0].get('latestCreatedDate'));
        System.assertEquals(0.00, (Decimal) result[0].get('totalValue'));
    }

   /**
    * Test to make sure that if there are no Lead records, the output still
    * provides data as expected, with "conversionRate" being zero,
    * and no exceptions are thrown for division by zero errors
    */
    @isTest
    static void testNoLeads() {
        Id testUserId = generateTestUser();

        standardSetupRecords(testUserId, 'Closed Won');

        Lead[] leads = [SELECT Id FROM Lead];
        delete leads;

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 2, 1),
                Date.newInstance(2020, 2, 28));
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('TestUser', (String) result[0].get('salesRepName'));
        System.assertEquals(0, (Integer) result[0].get('totalLeads'));
        System.assertEquals(1, (Integer) result[0].get('totalOpps'));
        System.assertEquals(0.0000, (Decimal) result[0].get('conversionRate'));
        System.assert(Date.newInstance(2020, 2, 15+5).isSameDay(
            ((DateTime) result[0].get('latestCreatedDate')).date()));
        System.assertEquals(100.00, (Decimal) result[0].get('totalValue'));
    }

   /**
    * Test to make sure that Opp aggregate calculations are working as intended:
    * Any Opp records with StageName not "Closed Won" are excluded from
    * those calculations
    */
    @isTest
    static void testOppAggregateCalcs() {
        Id testUserId = generateTestUser();
        Datetime testDatetime = Datetime.newInstance(2020, 2, 15, 12, 0, 0);

        Opportunity[] testOpps = new Opportunity[] {};
        for (Integer i = 1; i <= 5; i++) {
            testOpps.add(new Opportunity(
                Name='TestOpp' + i,
                CreatedDate=testDatetime.addDays(i),
                CloseDate=testDatetime.addDays(i*2).date(),
                Amount=100 * i,
                StageName='Closed Won',
                Is_Test_Opp__c=true,
                OwnerId=testUserId
            ));
        }

        testOpps[2].Amount = 999;
        testOpps[2].StageName = 'Qualifying';

        insert testOpps;

        Test.startTest();
        List<Map<String,Object>> result =
            UserController.fetchSalesRepPerformanceReport(
                Date.newInstance(2020, 2, 1),
                Date.newInstance(2020, 2, 28));
        Test.stopTest();

        System.assertEquals(1, result.size());
        System.assertEquals('TestUser', (String) result[0].get('salesRepName'));
        System.assertEquals(0, (Integer) result[0].get('totalLeads'));
        System.assertEquals(4, (Integer) result[0].get('totalOpps'));
        System.assertEquals(0.0000, (Decimal) result[0].get('conversionRate'));
        System.assert(Date.newInstance(2020, 2, 15+5).isSameDay(
            ((DateTime) result[0].get('latestCreatedDate')).date()));
        System.assertEquals(1200.00, (Decimal) result[0].get('totalValue'));
    }

    static void standardSetupRecords(Id userId, String stageName) {
        Datetime testDatetime = Datetime.newInstance(2020, 2, 15, 12, 0, 0);

        Lead newTestLead = new Lead(
            LastName='TestLead',
            Company='TestCompany',
            CreatedDate=testDatetime,
            Is_Test_Lead__c=true,
            OwnerId=userId
        );

        Opportunity newTestOpp = new Opportunity(
            Name='TestOpp',
            CreatedDate=testDatetime.addDays(5),
            CloseDate=testDatetime.addDays(10).date(),
            Amount=100,
            StageName=stageName,
            Is_Test_Opp__c=true,
            OwnerId=userId
        );

        insert newTestLead;
        insert newTestOpp;
    }

   /**
    * Test setup static method to generate test Users
    */
    static Id generateTestUser() {
        User testUser;
        String username = 'test@user.invaliddd';

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

        testUser = new User(
            LastName='TestUser',
            Username=username,
            Email=username,
            Alias='testuser',
            TimeZoneSidKey='America/New_York',
            LocaleSidKey='en_US',
            EmailEncodingKey='ISO-8859-1',
            ProfileId=p.Id,
            LanguageLocaleKey='en_US',

            Is_Test_User__c=true
        );

        insert testUser;

        return testUser.Id;
    }
}
