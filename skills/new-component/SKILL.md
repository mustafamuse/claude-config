---
allowed-tools: Read, Glob, Grep
argument-hint: [component-name] [ui|feature|form]
description: Generate a new React component following shadcn patterns
model: opus
---

# Generate New Component

Create component: $ARGUMENTS

## Instructions

1. **Parse Arguments**
   - Extract component name and type (ui, feature, or form)
   - Determine location based on type

2. **Component Types**

   | Type | Location | Pattern |
   |------|----------|---------|
   | `ui` | `components/ui/` | shadcn/Radix primitive |
   | `feature` | `app/[route]/_components/` | Feature-specific |
   | `form` | Feature location | react-hook-form + Zod |

3. **Generate Based on Type**

### UI Component (shadcn style)

```typescript
'use client'

import * as React from 'react'

import { cn } from '@/lib/utils'

interface [ComponentName]Props extends React.HTMLAttributes<HTMLDivElement> {
  // Additional props
}

const [ComponentName] = React.forwardRef<HTMLDivElement, [ComponentName]Props>(
  ({ className, ...props }, ref) => {
    return (
      <div
        ref={ref}
        className={cn('[base-classes]', className)}
        {...props}
      />
    )
  }
)
[ComponentName].displayName = '[ComponentName]'

export { [ComponentName] }
```

### Feature Component

```typescript
// Server Component by default (no 'use client' unless needed)
import { SomeUIComponent } from '@/components/ui/some-component'

interface [ComponentName]Props {
  // Props with types
}

export function [ComponentName]({ ...props }: [ComponentName]Props) {
  return (
    <div>
      {/* Implementation */}
    </div>
  )
}
```

### Form Component

```typescript
'use client'

import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { z } from 'zod'

import { Button } from '@/components/ui/button'
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form'
import { Input } from '@/components/ui/input'

const formSchema = z.object({
  // Schema definition
})

type FormData = z.infer<typeof formSchema>

interface [ComponentName]Props {
  onSubmit: (data: FormData) => Promise<void>
  defaultValues?: Partial<FormData>
}

export function [ComponentName]({ onSubmit, defaultValues }: [ComponentName]Props) {
  const form = useForm<FormData>({
    resolver: zodResolver(formSchema),
    defaultValues: defaultValues ?? {},
  })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <FormField
          control={form.control}
          name="fieldName"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Label</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Submit</Button>
      </form>
    </Form>
  )
}
```

## Reference Components

- UI patterns: `components/ui/button.tsx`, `components/ui/select.tsx`
- Form patterns: `components/registration/shared/` directory
- Feature patterns: `app/admin/dugsi/components/` directory

## Component Rules

- Server Components by default (App Router)
- Only add `'use client'` when interactivity required
- Use `cn()` utility for className merging
- Use `React.forwardRef` for UI primitives
- Extract Zod schema to shared location if reused
- Props interface always typed (no `any`)
