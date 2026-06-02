@IsTest
public class VRT_CLS_VehicleRevisionSchedule_Test {
    @IsTest
    static void testSchedulerRunsBatch() {
        Test.startTest();
        String jobId = System.schedule('TestSchedule', '0 0 10 * * ?', new VRT_CLS_VehicleRevisionSchedule());
        Test.stopTest();
        System.assertNotEquals(null, jobId, 'Debe devolver un jobId');
    }
}