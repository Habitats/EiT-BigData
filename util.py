# -*- coding: utf-8 -*-
import time

def normalizeDate(input):
  try:
    date = time.strptime(input, "%d %B %Y")
    return time.strftime("%Y-%m-%d", date)
  except ValueError:
    date = None

  if not date:
    try:
      date = time.strptime(input, "%Y")
      return time.strftime("%Y-%m-%d", date)
    except ValueError:
      return None

def normalizeCurrency(currency):
  if currency == "£":
    return "GBP"
  elif currency == "$":
    return "USD"
  elif currency == "€":
    return "EUR"
  else:
    return currency

def convertToUsd(amount, currency):
  # Average fx for 2005-2010 (jan-jan)
  # source: http://www.oanda.com/currency/historical-rates/

  # TODO - fix this
  rates = {
    "GBP": 1.7030,
    "USD": 1,
    "EUR": 1.3399,
    "ESP": 0.0081,
    "SEK": 0.1443,
    "AUD": 0.8856,
    "PHP": 0.0218,
    "ITL": 0.0007,
    "INR": 0.0208,
    "HKD": 0.1287,
    "CAD": 0.9325,
    "BRL": 0.5013,
    "NOK": 0.1643,
    "GRD": 0.0040,
    "DKK": 0.1807,
    "MXN": 0.0879,
    "NZD": 0.6876,
    "CHF": 0.9617,
    "DEM": 0.6887,
    "ARS": 0.3138
  }

  if currency in rates:
    return amount * rates[currency]
  else:
    return None


