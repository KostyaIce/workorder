package com.konstantin.workorder;

import android.app.Activity;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.ContactsContract;

public final class ContactPickerHelper {
    private static final int REQUEST_CODE = 0x574f;

    private ContactPickerHelper() {
    }

    public static void pick(Activity activity) {
        Intent intent = new Intent(Intent.ACTION_PICK,
                ContactsContract.CommonDataKinds.Phone.CONTENT_URI);
        activity.startActivityForResult(intent, REQUEST_CODE);
    }

    public static String[] selectedContact(Activity activity, Intent data) {
        if (data == null || data.getData() == null) {
            return null;
        }

        Uri uri = data.getData();
        String[] projection = new String[] {
                ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                ContactsContract.CommonDataKinds.Phone.NUMBER
        };

        try (Cursor cursor = activity.getContentResolver().query(uri, projection, null, null, null)) {
            if (cursor != null && cursor.moveToFirst()) {
                String name = cursor.getString(0);
                String phone = cursor.getString(1);
                return new String[] { name == null ? "" : name, phone == null ? "" : phone };
            }
        } catch (Exception ignored) {
        }
        return null;
    }
}
