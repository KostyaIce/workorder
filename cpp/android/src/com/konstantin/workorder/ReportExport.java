package com.konstantin.workorder;

import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.util.Log;

import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.OutputStream;

/**
 * Copies a saved PDF into the public Downloads folder and opens the system share sheet.
 */
public final class ReportExport
{
    private static final String TAG = "WorkOrderReportExport";

    private ReportExport()
    {
    }

    public static String publishAndShare(Context context, String sourcePath)
    {
        if(context == null || sourcePath == null || sourcePath.isEmpty())
        {
            Log.e(TAG, "publishAndShare: invalid arguments");
            return "";
        }

        final File source = new File(sourcePath);
        if(!source.isFile())
        {
            Log.e(TAG, "publishAndShare: file missing: " + sourcePath);
            return "";
        }

        final String mime = mimeFor(source.getName());
        Uri shared = null;
        String place = "";
        if(Build.VERSION.SDK_INT >= 29)
        {
            shared = copyToDownloads(context, source, mime);
            if(shared != null)
                place = "Загрузки";
        }

        if(shared == null)
        {
            shared = fileProviderUri(context, source);
            place = "папку приложения";
        }
        if(shared == null)
            return "";

        if(!share(context, shared, mime))
            return "";
        return place;
    }

    private static String mimeFor(String name)
    {
        if(name != null && name.toLowerCase().endsWith(".xlsx"))
            return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
        return "application/pdf";
    }

    private static Uri copyToDownloads(Context context, File source, String mime)
    {
        try
        {
            final ContentValues values = new ContentValues();
            values.put(MediaStore.MediaColumns.DISPLAY_NAME, source.getName());
            values.put(MediaStore.MediaColumns.MIME_TYPE, mime);
            values.put(MediaStore.MediaColumns.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS + "/WorkOrder");
            values.put(MediaStore.MediaColumns.IS_PENDING, 1);

            final Uri item = context.getContentResolver().insert(
                MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                values);
            if(item == null)
                return null;

            try(InputStream input = new FileInputStream(source);
                OutputStream output = context.getContentResolver().openOutputStream(item))
            {
                if(output == null)
                    return null;
                final byte[] buffer = new byte[8192];
                int read;
                while((read = input.read(buffer)) > 0)
                    output.write(buffer, 0, read);
            }

            values.clear();
            values.put(MediaStore.MediaColumns.IS_PENDING, 0);
            context.getContentResolver().update(item, values, null, null);
            Log.i(TAG, "copyToDownloads: " + item);
            return item;
        }
        catch(Exception e)
        {
            Log.e(TAG, "copyToDownloads failed", e);
            return null;
        }
    }

    private static Uri fileProviderUri(Context context, File source)
    {
        try
        {
            final String authority = context.getPackageName() + ".qtprovider";
            return FileProvider.getUriForFile(context, authority, source);
        }
        catch(Exception e)
        {
            Log.e(TAG, "fileProviderUri failed", e);
            return null;
        }
    }

    private static boolean share(Context context, Uri uri, String mime)
    {
        try
        {
            final Intent sendIntent = new Intent(Intent.ACTION_SEND);
            sendIntent.putExtra(Intent.EXTRA_STREAM, uri);
            sendIntent.setType(mime);
            sendIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

            final Intent chooser = Intent.createChooser(sendIntent, "Отправить файл");
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(chooser);
            return true;
        }
        catch(Exception e)
        {
            Log.e(TAG, "share failed", e);
            return false;
        }
    }
}
