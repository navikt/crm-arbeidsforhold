/**
 * This is the test class for the AAREG_CacheController class.
 * <br><br>
 * @author Ashish Misra
 * @since Juni 2026
 * @group Cache Controller
 */
@IsTest
public class AAREG_CacheControllerTest {
    @IsTest
    static void WhenCacheIsSet_ReadingCacheReturnsValue() {
        String key = 'testKey';
        String value = 'testValue';

        // Set cache value
        AAREG_CacheController.setCacheValue(key, value);

        // Get cache value
        String cachedValue = AAREG_CacheController.getCacheValue(key);

        // Verify the cached value
        System.assertEquals(value, cachedValue, 'The cached value should match the set value.');
    }

        @IsTest
        static void WhenKeyDoesNotExist_ReturnsNull() {
            String missingKey = 'missingKey';

            Test.startTest();
            String cachedValue = AAREG_CacheController.getCacheValue(missingKey);
            Test.stopTest();

            System.assertEquals(null, cachedValue, 'Non-existing cache key should return null.');
        }

        @IsTest
        static void WhenValueIsNull_ReturnsNullOnGet() {
            String key = 'nullValueKey';

            Test.startTest();
            AAREG_CacheController.setCacheValue(key, null);
            String cachedValue = AAREG_CacheController.getCacheValue(key);
            Test.stopTest();

            System.assertEquals(null, cachedValue, 'Cache should store and return null value for existing key.');
        }

        @IsTest
        static void WhenSameKeyUpdated_ReturnsLatestValue() {
            String key = 'sameKey';
            String firstValue = 'first';
            String secondValue = 'second';

            Test.startTest();
            AAREG_CacheController.setCacheValue(key, firstValue);
            AAREG_CacheController.setCacheValue(key, secondValue);
            String cachedValue = AAREG_CacheController.getCacheValue(key);
            Test.stopTest();

            System.assertEquals(secondValue, cachedValue, 'Latest value should overwrite previous value for same key.');
        }
}