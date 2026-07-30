/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "macosstatusicon.h"
#include "leakdetector.h"
#include "logger.h"

#include <QMenu>

#import <Cocoa/Cocoa.h>
#import <UserNotifications/UserNotifications.h>
#import <QResource>

namespace {
Logger logger("MacOSStatusIcon");

// Padding, in points, between the status item image and the menu bar edges.
constexpr CGFloat kStatusIconInset = 4.0;
}  // namespace

MacOSStatusIcon::MacOSStatusIcon(QObject* parent) : QObject(parent) {
  MZ_COUNT_CTOR(MacOSStatusIcon);

  NSStatusItem* item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
  item.visible = YES;
  m_statusItem = [item retain];
}

MacOSStatusIcon::~MacOSStatusIcon() {
  MZ_COUNT_DTOR(MacOSStatusIcon);

  Q_ASSERT(m_statusItem);

  m_statusItem.menu = nil;
  [[NSStatusBar systemStatusBar] removeStatusItem:m_statusItem];
  [m_statusItem release];
  m_statusItem = nullptr;
}

void MacOSStatusIcon::setIcon(const QString& iconPath) {
  logger.debug() << "Set icon" << iconPath;

  QResource resource(iconPath);
  if (!resource.isValid()) {
    logger.error() << "Invalid status icon resource" << iconPath;
    return;
  }

  NSImage* image = [[NSImage alloc] initWithData:resource.uncompressedData().toNSData()];
  CGFloat side = [[NSStatusBar systemStatusBar] thickness] - kStatusIconInset;
  image.size = NSMakeSize(side, side);
  m_statusItem.button.image = image;
  [image release];
}

void MacOSStatusIcon::setMenu(QMenu* menu) {
  logger.debug() << "Set menu";

  m_statusItem.menu = menu ? menu->toNSMenu() : nil;
}

void MacOSStatusIcon::showMessage(const QString& title, const QString& message) {
  logger.debug() << "Show message";

  UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];

  // The completion handlers below run on an arbitrary queue and therefore use
  // NSLog rather than Logger, whose LogStreamer writes to a shared QFile
  // without locking.

  // This is a no-op if authorization has already been granted.
  [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert |
                                           UNAuthorizationOptionBadge)
                        completionHandler:^(BOOL granted, NSError* _Nullable error) {
                          if (error) {
                            // Note: this error may happen if the application is not signed.
                            NSLog(@"Error asking for permission to send notifications %@", error);
                            return;
                          }
                          if (!granted) {
                            NSLog(@"Permission to send notifications was denied");
                          }
                        }];

  UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
  content.title = title.toNSString();
  content.body = message.toNSString();
  content.sound = [UNNotificationSound defaultSound];

  UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"amneziavpn"
                                                                        content:content
                                                                        trigger:nil];
  [content release];

  [center addNotificationRequest:request
           withCompletionHandler:^(NSError* _Nullable error) {
             if (error) {
               NSLog(@"Local notification failed %@", error);
             }
           }];
}
