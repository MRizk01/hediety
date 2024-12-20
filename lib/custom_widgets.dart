import 'package:flutter/material.dart';

    class CustomTextFormField extends StatelessWidget {
      final TextEditingController controller;
      final String labelText;
      final String? Function(String?)? validator;
      final TextInputType? keyboardType;
      final bool readOnly;

       const CustomTextFormField({
        super.key,
        required this.controller,
         required this.labelText,
          this.validator,
        this.keyboardType,
        this.readOnly = false,
        });

      @override
      Widget build(BuildContext context) {
        return TextFormField(
            controller: controller,
            decoration: InputDecoration(labelText: labelText),
           validator: validator,
          keyboardType: keyboardType,
           readOnly: readOnly,
          );
        }
     }

   class CustomElevatedButton extends StatelessWidget {
     final VoidCallback onPressed;
     final Widget child;

      const CustomElevatedButton({
         super.key,
        required this.onPressed,
         required this.child,
        });

      @override
       Widget build(BuildContext context) {
          return ElevatedButton(
             onPressed: onPressed,
               child: child,
          );
       }
    }