/**
* CacheController.cls
* This Apex class provides methods to set and get cache values using the Cache.Session class.
* The setCacheValue method allows you to store a value in the cache with a specified key.
* The getCacheValue method retrieves the value associated with the specified key from the cache.      
* @author Ashish Misra   
 */
public with sharing class AAREG_CacheController {

    @TestVisible
    private static Map<String, String> fallbackSessionCache = new Map<String, String>();

    @AuraEnabled
    public static void setCacheValue(String key, String value) {
        try {
            Cache.Session.put(key, value);
        } catch (Exception e) {
            // Fallback for orgs/tests without a default session cache partition.
            fallbackSessionCache.put(key, value);
        }
    }

    @AuraEnabled(cacheable=true)
    public static String getCacheValue(String key) {
        try {
            return (String) Cache.Session.get(key);
        } catch (Exception e) {
            return fallbackSessionCache.get(key);
        }
    }
}