# Manipulator Plugin

This is an simple plugin to extend text manipulation in Micro.

## Keybindings
By default no keybindings exist, but you can easily modify that
in your `bindings.json` file:

```json
{
    "Ctrl-Shift-L": "manipulator.lower"
}
```

You can also execute a command which will do the same thing as
the binding:

```
> upper
```

If you have a selection, the plugin will change all the lines
selected.

The following commands currently exists:
 * `upper`: Converts to UPPERCASE
 * `lower`: Converts to lowercase
