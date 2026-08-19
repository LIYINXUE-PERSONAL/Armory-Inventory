# Firearm configuration inheritance

## Goal

Allow a barrel, slide, or upper receiver to describe its own optional caliber and
barrel length without modifying the values stored on the firearm. Firearm values
remain the editable fallback and inherited values are resolved only for display.

## Data model

`Part` stores optional `caliber` and `barrelLengthInches` properties. The part
editor exposes them only when the selected type is barrel, slide, or upper
receiver. Changing a part to any other type clears both properties when saved so
unsupported parts cannot silently affect a firearm.

## Resolution

Resolution collects both directly attached parts and parts in every kit attached
to the firearm. Each field is resolved independently using this priority:

1. Barrel
2. Slide
3. Upper receiver
4. The firearm's stored value

Thus, a barrel that specifies only length does not hide a slide's caliber. The
resolver returns both the effective value and its source, and never writes either
result back to a firearm or another part.

## User experience

In a firearm's read-only details and expanded inventory card, caliber and barrel
length show the resolved values. When an inherited value appears in details, a
note identifies the source part by name and warns that editing the firearm value will not
change the displayed value while that part remains attached.

After the user selects **Edit**, the controls contain the firearm's own stored
values. This makes it possible to update the fallback without accidentally
editing or copying a part's configuration.
