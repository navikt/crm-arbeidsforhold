/**
* CacheController.cls
* This Apex class provides methods to set and get cache values using the Cache.Session class.
* The setCacheValue method allows you to store a value in the cache with a specified key.
* The getCacheValue method retrieves the value associated with the specified key from the cache.      
* @author Ashish Misra   
 */
public with sharing class CacheController {

    @AuraEnabled
    public static void setCacheValue(String key, String value) {
        Cache.Session.put(key, value);
    }

    @AuraEnabled(cacheable=true)
    public static String getCacheValue(String key) {
        return (String) Cache.Session.get(key);
    }
}