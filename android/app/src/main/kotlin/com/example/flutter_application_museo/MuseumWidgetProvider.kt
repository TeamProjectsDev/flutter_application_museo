package com.example.flutter_application_museo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class MuseumWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            val widgetData = HomeWidgetPlugin.getData(context)
            val views = RemoteViews(context.packageName, R.layout.museum_widget).apply {
                
                val title = widgetData.getString("title", "Museo Vivo 4.0")
                setTextViewText(R.id.widget_title, title)
                
                val message = widgetData.getString("message", "¡Escanea tu próxima pieza!")
                setTextViewText(R.id.widget_message, message)

                val lastItem = widgetData.getString("last_item", "Ninguno todavía")
                setTextViewText(R.id.widget_extra, "Último: $lastItem")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
