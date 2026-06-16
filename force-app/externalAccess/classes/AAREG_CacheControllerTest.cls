@IsTest
public class AAREG_CacheControllerTest {
    @IsTest
    static void testSetAndGetCacheValue() {
        String key = 'testKey';
        String value = 'testValue';

        // Set cache value
        AAREG_CacheController.setCacheValue(key, value);

        // Get cache value
        String cachedValue = AAREG_CacheController.getCacheValue(key);

        // Verify the cached value
        System.assertEquals(value, cachedValue, 'The cached value should match the set value.');
    }
}